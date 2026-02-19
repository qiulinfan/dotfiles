# Dotfiles

Personal configuration for:

- fish
- neovim

为了保持 clean. 我们的做法是: 

- 在 ~ 下创建了一个 dotfiles directory
- `~/dotfiles/` 中的 directories symlink 到了 `~/.config/` 里面
- 这样, 每当在新机器或新服务器上想要迁移 configs, 就可以直接 clone 这个 repo 然后跑 `initial.sh`; 并且管理 configs 也更方便.



## Installation

Clone into home directory:

```bash
cd ~
git clone git@github.com:yourname/dotfiles.git ~/dotfiles
```

Run setup:

```bash
cd ~/dotfiles
bash initial.sh
```



## Notes

- This script creates symbolic links
- Existing configs will be backed up automatically
- Requires fish and neovim installed