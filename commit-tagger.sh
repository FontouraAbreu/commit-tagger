#!/bin/bash
# update tag in the x.y.z format based on the -v argument [major|minor|patch|dev]
# update the version in the .env file

main() {
    parse_args "$@"
    check_git_status
    update_version "$VERSION"
    git_update_file
    git_push
    git_tag
    git_push_tag
    if [[ $AS_LATEST == true ]]; then
        git_tag latest
        git_push_tag latest
    fi
}

parse_args() {
    # parse the arguments

    # check if the version argument is passed
    while [[ $# -gt 0 ]]; do        
        case "$1" in
            -h|--help)
                echo -e "Usage: commit-tagger [POSITIONAL] [OPTIONS]"
                echo -e "Positional"
                echo -e "      [major|minor|patch|dev]  The version you are updating\n\
                               [dev] shall be used only to tag development commits(can't be used with --as-latest)"
                echo
                echo -e "Options"
                echo -e "      -f|--file [file]\t\tThe file where the version is stored. Default is .env"
                echo -e "      -c|--commit [commit]\tThe commit you want to tag. Default is the current commit"
                echo -e "      --as-latest\t\tAlso tag the commit as \"latest\". CAREFUL: This will overwrite the current \"latest\" tag"
                echo -e "      -h|--help\t\t\tShow this help message"
                exit 0
                ;;

            major|minor|patch|dev)
                if [[ $AS_LATEST == true &&  $1 == "dev" ]]; then
                    echo "dev can't be used with --as-latest"
                    parse_args -h
                    exit 1
                fi
                # if version is [major|minor|patch|dev] then update the version
                VERSION="$1"
                shift
                ;;


            # optional -f|--file argument
            -f|--file)
                # if file is passed then update the file
                if [[ -f "$2" ]]; then
                    FILE="$2"
                else
                    echo "Invalid file argument"
                    parse_args -h
                    exit 1
                fi
                shift
                shift
                ;;

            -c|--commit)
                # if commit is passed then update the commit
                if [[ -n "$2" ]]; then
                    COMMIT="$2"
                else
                    echo "Invalid commit argument"
                    commit-tagger -h
                    exit 1
                fi
                shift
                shift
                ;;

            --as-latest)
                if [[ $VERSION == "dev" ]]; then
                    echo "dev can't be used with --as-latest"
                    parse_args -h
                    exit 1
                fi
                AS_LATEST=true
                shift
                ;;
            
            # if the argument is not valid then call the help function and exit
            *)
                echo "Invalid argument"
                parse_args -h
                exit 1
                ;;
            
        esac

    done

    # if file is not passed then use the default env file
    if [[ -z "$FILE" ]]; then
        FILE=".env"
    fi
    
    # check if the version argument is passed
    if [[ -z "$VERSION" ]]; then
        echo "Version argument is required"
        parse_args -h
        exit 1
    fi
}

git_update_file() {
    # update the file in the git
    git add $FILE
    git commit -m "[update] version to $UPDATED_VERSION"
}

git_push_tag() {
    if [[ $1 == "latest" ]]; then
        UPDATED_VERSION="latest"
    fi
    # push the tag to the remote
    git push origin -f "$UPDATED_VERSION"
    # check if the tag is pushed
    if [[ $(git ls-remote --tags origin | grep -oP "$UPDATED_VERSION") ]]; then
        echo "Tag pushed"
    else
        echo "Tag not pushed, please try again"
        exit 1
    fi
}

git_tag() {
    # create the tag based on the version
    if [[ -n "$COMMIT" ]]; then
        git tag -f "$UPDATED_VERSION" "$COMMIT"
        # if "latest" is passed then tag the commit as "latest
        if [[ -n $1 && $1 == "latest" ]]; then
            git tag -f latest "$COMMIT"
        fi
    else
        # tag the current commit with the version
        git tag -f "$UPDATED_VERSION"
        if [[ -n $1 && $1 == "latest" ]]; then
            git tag -f latest
        fi
    fi

    # check if the tag is created
    if [[ $1 != "latest" && $(git tag | grep -oP "$UPDATED_VERSION") ]]; then
        echo "Tag ${UPDATED_VERSION} created"
    elif [[ -n $AS_LATEST && $(git tag | grep -oP "latest") ]]; then
        echo "Tag \"latest\" created"
    else
        echo "Tag not created, please try again"
        exit 1
    fi
}

git_push() {
    # push the changes to the remote
    
    git push

    # check if the changes have been pushed
    if [[ $(git status -uno | grep -oP '(?<=Your branch is up to date with).+') ]]; then
        echo "Changes pushed"
    else
        echo "Changes not pushed, please try again"
        exit 1
    fi
}

check_git_status() {    
    # return the git status on variable GIT_STATUS
    # GIT_STATUS can be [behind|uncommitted|merge_conflict]

    STATUS_MESSAGE=$(git status -uno)
    # check if is not behind the remote
    if [[ $(echo ${STATUS_MESSAGE} | grep -oP '(?<=Your branch is behind).+') ]]; then
        GIT_STATUS="behind"
    # check if it has uncommitted changes
    elif [[ $(echo ${STATUS_MESSAGE} | grep -oP '(?<=Changes not staged for commit:).+') ]]; then
        GIT_STATUS="not_staged"
    # check if it has staged changes
    elif [[ $(echo ${STATUS_MESSAGE} | grep -oP '(?<=Changes to be committed:).+') ]]; then
        GIT_STATUS="uncommitted"
    # check if there is a merge conflict
    elif [[ $(echo ${STATUS_MESSAGE} | grep -oP '(?<=You have unmerged paths.)') ]]; then
        GIT_STATUS="merge_conflict"
    else
        GIT_STATUS="clean"
    fi

    # check if the git status is clean
    if [[ "$GIT_STATUS" != "clean" ]]; then
        echo "Git status is not clean"
        echo "Please check the status and try again"
        echo "Git status:"
        echo "$STATUS_MESSAGE"
        exit 1
    fi

}

update_version() {
    # update the version in the env file based on the argument
    # follows the x.y.z format

    # if the file does not exist then exit
    if [[ ! -f "$FILE" ]]; then
        echo "File $FILE does not exist"
        echo "Please create the file with the following format: VERSION=x.y.z"
        echo "Where x, y and z are numbers following the x.y.z versioning format"
        exit 1
    fi

    # get the current version
    CURRENT_VERSION=$(grep -oP '(?<=VERSION=).+' $FILE)
    if [[ -z "$CURRENT_VERSION" ]]; then
        echo "Invalid version in the ${FILE} file"
        echo "Should be like: VERSION=x.y.z"
        exit 1
    fi


    # split the version into an array
    IFS='.' read -ra VERSION_ARRAY <<< "$CURRENT_VERSION"
    
    # get the major version
    MAJOR_VERSION=${VERSION_ARRAY[0]}
    # get the minor version
    MINOR_VERSION=${VERSION_ARRAY[1]}
    # get the patch version
    PATCH_VERSION=${VERSION_ARRAY[2]}
    
    # update the version based on the argument
    if [[ "$1" == "major" ]]; then
        MAJOR_VERSION=$((MAJOR_VERSION + 1))
        MINOR_VERSION=0
        PATCH_VERSION=0
    elif [[ "$1" == "minor" ]]; then
        MINOR_VERSION=$((MINOR_VERSION + 1))
        PATCH_VERSION=0
    elif [[ "$1" == "patch" ]]; then
        PATCH_VERSION=$((PATCH_VERSION + 1))
    elif [[ "$1" == "dev" ]]; then
        UPDATED_VERSION="dev"
        echo "Updating dev tag"
        return
    elif [[ $AS_LATEST == true ]]; then
        echo "Also updating \"latest\" tag"
        return
    else
        echo "Invalid version argument"
        exit 1
    fi

    # update the current version
    UPDATED_VERSION="$MAJOR_VERSION.$MINOR_VERSION.$PATCH_VERSION"

    echo "Updating $CURRENT_VERSION to $UPDATED_VERSION."

    # update the version in the env file
    sed -i "s/VERSION=.*/VERSION=${UPDATED_VERSION}/g" ${FILE}
}

main "$@"