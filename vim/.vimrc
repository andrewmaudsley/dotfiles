set nocompatible              " be iMproved, required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'Lokaltog/vim-distinguished'
Plugin 'jelera/vim-javascript-syntax'
Plugin 'Valloric/YouCompleteMe'
Plugin 'ternjs/tern_for_vim'
Plugin 'pangloss/vim-javascript'
Plugin 'Raimondi/delimitMate'
Plugin 'mhinz/vim-signify'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'tpope/vim-fugitive'
Plugin 'mxw/vim-jsx'
Plugin 'SirVer/ultisnips'
Plugin 'epilande/vim-es2015-snippets'
Plugin 'epilande/vim-react-snippets'
Plugin 'scrooloose/nerdcommenter'
Plugin 'alvan/vim-closetag'
Plugin 'JamshedVesuna/vim-markdown-preview'
Plugin 'wincent/command-t'
Plugin 'prettier/vim-prettier'
Plugin 'mileszs/ack.vim'
Plugin 'mkitt/tabline.vim'
Plugin 'w0rp/ale'
Plugin 'airblade/vim-gitgutter'
Plugin 'leafgarland/typescript-vim'
Plugin 'peitalin/vim-jsx-typescript'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

syntax enable
set background=dark
colorscheme solarized
set laststatus=2
let g:airline_theme='solarized'
let g:airline_solarized_normal_green=1
let g:jsx_ext_required = 0
set ttimeoutlen=50
set tabstop=8 softtabstop=0 expandtab shiftwidth=2 smarttab
set autoindent
set smartindent
set number
set backspace=indent,eol,start
nmap <S-Enter> O<Esc>
nmap <CR> o<Esc>

" Search config
let g:CommandTWildIgnore=&wildignore . ",*/node_modules,*/build,*/lib,*/dist"
cnoreabbrev Ack Ack!
nnoremap <Leader>a :Ack!<Space>
if executable('ag')
  let g:ackprg = 'ag --vimgrep --smart-case'
endif

" bind K to search word under cursor
nnoremap K :Ack! "\b<C-R><C-W>\b"<CR>:cw<CR>

" UltiSnips trigger configuration. Do not use <tab> if you use
" https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<C-l>"

" NERDTree config
let NERDTreeMinimalUI=1
let g:NERDTreeShowHidden=1
let g:NERDTreeWinPos="left"
let NERDTreeIgnore=['\.swp$', '\~$', '\.DS_Store$']
nnoremap <F4> :NERDTreeToggle<CR>
let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.js'

" Markdown config
let vim_markdown_preview_github=1

" Configure Asynchronous Lint Engine
let g:ale_fixers = {
 \ 'javascript': ['eslint']
 \ }

let g:ale_fix_on_save = 1
let g:airline#extensions#ale#enabled = 1
