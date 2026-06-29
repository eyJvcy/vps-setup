#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

echo "============================================"
echo "  CONFIGURATION VIM"
echo "============================================"
echo ""

for user in $VPS_USERS; do
    log_step "Configuration Vim pour: $user"
    
    # Installer vim-plug
    log_substep "Installation vim-plug..."
    su - $user -c "curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    
    # Créer .vimrc
    log_substep "Création .vimrc..."
    cat > /home/$user/.vimrc <<'EOF'
" Configuration Vim - Auto-generated
set nocompatible

" Plugins
call plug#begin('~/.vim/plugged')
Plug 'morhetz/gruvbox'
Plug 'vim-airline/vim-airline'
Plug 'preservim/nerdtree'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'
Plug 'airblade/vim-gitgutter'
call plug#end()

" Général
set number
set relativenumber
set hlsearch
set incsearch
set ignorecase
set smartcase
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set showcmd
set showmatch
set wildmenu
set cursorline
set laststatus=2
set mouse=a
set nobackup
set noswapfile

" Thème
syntax enable
set background=dark
try
    colorscheme gruvbox
catch
    colorscheme desert
endtry

" Raccourcis
let mapleader = ","
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>n :NERDTreeToggle<CR>

" Compilation C/C++
nnoremap <F5> :!gcc -Wall -Wextra -Werror % -o %< && ./%<<CR>
nnoremap <F6> :!g++ -Wall -Wextra -Werror -std=c++17 % -o %< && ./%<<CR>
nnoremap <F7> :!valgrind --leak-check=full ./%<<CR>

" Retour dernière position
autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

" Supprimer espaces en fin de ligne
autocmd BufWritePre * :%s/\s\+$//e
EOF
    
    chown $user:$user /home/$user/.vimrc
    
    # Installer les plugins
    log_substep "Installation des plugins..."
    su - $user -c "vim +PlugInstall +qall" 2>/dev/null || true
    
    log_success "✅ Vim configuré pour $user"
    echo ""
done

echo ""
log_success "✅ Configuration Vim terminée"
log_info "Raccourcis:"
echo "  • ,w    → Sauvegarder"
echo "  • ,q    → Quitter"
echo "  • ,n    → NERDTree"
echo "  • F5    → Compiler et exécuter C"
echo "  • F6    → Compiler et exécuter C++"
echo "  • F7    → Valgrind"
echo ""