# commit-tagger

Um script para facilitar a criação de tags e versionamento do seu projeto no git.

## Help

```bash
commit-tagger -h
```

```text
Usage: commit-tagger [POSITIONAL] [OPTIONS]
Positional
      [major|minor|patch|dev]  The version you are updating
                               [dev] shall be used only to tag development commits

Options
      -f|--file [file]          The file where the version is stored. Default is .env
      -c|--commit [commit]      The commit you want to tag. Default is the last commit
      -h|--help                 Show this help message
```

## Como usar

1. Clone o repositório

2. Crie um link simbólico para o script dentro do seu PATH

    ```bash
    sudo ln -s $(pwd)/commit-tagger.sh /usr/local/bin/commit-tagger
    ```

3. Execute o script dentro do seu projeto

    ```bash
    cd /path/to/your/project
    commit-tagger -h
    ```

## Roadmap

- [x] Implementar a flag "--as-latest". Para que a versão mais recente seja também taggeada como "latest"
- [ ] Implementar auto-complete para o script
