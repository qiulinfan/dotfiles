# Dotfiles

这里保存 fish、Vim、Neovim 和 Git 的个人配置。

这个仓库通过软链接应用配置：

```text
~/.config/fish -> ~/dotfiles/fish
~/.config/nvim -> ~/dotfiles/nvim
~/.vimrc       -> ~/dotfiles/vim/.vimrc
~/.gitconfig   -> ~/dotfiles/git/.gitconfig
```

如果目标位置已经存在文件或目录，脚本会自动备份成 `<路径>.bak.<时间戳>`。

## 快速开始

新 Ubuntu/WSL 机器上，如果已经有 GitHub SSH 权限：

```bash
cd ~
git clone git@github.com:qiulinfan/dotfiles.git ~/dotfiles
cd ~/dotfiles
./initial.sh --all
```

如果还没有配置 GitHub SSH key，先用 HTTPS clone：

```bash
cd ~
git clone https://github.com/qiulinfan/dotfiles.git ~/dotfiles
cd ~/dotfiles
./initial.sh --all
```

脚本会打印新生成的 SSH public key。把它加到 GitHub 之后，可以把 remote 切回 SSH：

```bash
git remote set-url origin git@github.com:qiulinfan/dotfiles.git
```

## 脚本用法

默认只创建软链接，不安装软件、不改系统设置：

```bash
./initial.sh
```

一键安装常用依赖并应用配置：

```bash
./initial.sh --all
```

也可以分步执行：

```bash
./initial.sh --install-apt          # apt 安装 git, fish, vim, gcc/g++-13, gdb, fzf, rg, clipboard tools 等基础包
./initial.sh --install-nvim         # 安装最新版 Neovim 到 /opt，并链接到 /usr/local/bin/nvim
./initial.sh --install-editor-deps  # 安装 vim-plug, Node.js 20, yarn, tree-sitter-cli, lazygit, bottom/btm
./initial.sh --install-fonts        # 安装 JetBrainsMono Nerd Font
./initial.sh --ssh-key              # 创建 ~/.ssh/id_ed25519，并打印 public key
./initial.sh --set-fish-shell       # 把 fish 加入 /etc/shells，并设为默认 shell
```

`--install-vim-deps` 是 `--install-editor-deps` 的兼容别名。

注意：`npm` 不放在 `--install-apt` 里安装。脚本会在 `--install-editor-deps` 阶段通过 NodeSource 安装 Node.js 20，并使用它自带的 `npm`，避免 Ubuntu 自带 `npm` 和 NodeSource `nodejs` 的依赖冲突。

查看帮助：

```bash
./initial.sh --help
```

## 设置 fish 为默认 shell

Linux 上可以运行：

```bash
./initial.sh --install-apt --set-fish-shell
```

脚本会用 `command -v fish` 找到 fish 路径；如果这个路径还不在 `/etc/shells`，就自动追加进去，然后执行：

```bash
sudo chsh -s "$(command -v fish)" "$USER"
```

执行完以后，重新打开终端才会生效。

## Neovim

Neovim 配置在 `nvim/`，基于 AstroNvim。

推荐安装方式：

```bash
./initial.sh --install-nvim --install-editor-deps --install-fonts
nvim
```

`--install-nvim` 会移除 apt 里的旧 `neovim`/`neovim-runtime`，下载 GitHub release tarball，安装到 `/opt/nvim-linux-x86_64`，并创建 `/usr/local/bin/nvim` 软链接。

## Vim

Vim 配置在 `vim/.vimrc`。

安装插件依赖：

```bash
./initial.sh --install-editor-deps
vim
```

然后在 Vim 里运行：

```vim
:PlugInstall
```

更多 Vim 记录在 `vim/vim.md`。

## 检查

```bash
ls -l ~/.config/fish ~/.config/nvim ~/.vimrc ~/.gitconfig
command -v nvim && nvim --version | head -n 1
git config --global --list
```

配置应用之后，直接修改 `~/dotfiles` 里的文件即可；实际使用的配置路径会通过软链接指回这里。
