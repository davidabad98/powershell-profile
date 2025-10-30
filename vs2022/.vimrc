" ========== Basic ==========
set number
set relativenumber
 
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
 
set nowrap
set cursorline
set scrolloff=8
" signcolumn is a Neovim/terminal thing; VsVim ignores it
 
" ========== Search ==========
set ignorecase
set smartcase
"set hlsearch
set incsearch
 
" ========== Clipboard ==========
" VsVim already integrates with the Windows clipboard.
" 'unnamedplus' is Neovim-specific; use 'unnamed' if you want to force it.
set clipboard=unnamed
 
" ========== UI ==========
set splitbelow
set splitright
" termguicolors and colorcolumn are UI/terminal features; not used by VsVim.
" Add a column/ruler at 88 in VS itself (see notes below).
 
" ========== Leader & basic keymaps ==========
let mapleader=" "
nnoremap <Space> <Nop>
 
" Quick save / quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>
 
" ========== Navigation ==========
" Buffer/document navigation (works as 'next/prev open document' in VsVim)
nnoremap <S-h> :bprevious<CR>
nnoremap <S-l> :bnext<CR>
 
" Splits (VS splits the current editor view)
nnoremap <leader>v :vsplit<CR>
nnoremap <leader>s :split<CR>
nnoremap <leader>n :vnew<CR>
" Tabs (Vim tabpages aren't really a thing in VS; see notes)
" nnoremap <leader>t :tabnew<CR>
 
" Window navigation via leader
nnoremap <leader>h <C-w>h
nnoremap <leader>j <C-w>j
nnoremap <leader>k <C-w>k
nnoremap <leader>l <C-w>l
 
" Center the view when moving up and down
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
 
" Center the view when searching
nnoremap n nzzzv
nnoremap N Nzzzv
 
" ========== Developer Essentials ==========
" Keep selection when indenting in visual mode
vnoremap < <gv
vnoremap > >gv
 
" Move selected lines up/down and keep selection
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv
"These dont work:
"vnoremap J :<C-U>silent! '<,'>move '>+1<CR>'<,'>normal! gv=gv
"vnoremap K :<C-U>silent! '<,'>move '<-2<CR>'<,'>normal! gv=gv
 
" Visual mode: paste over selection without overwriting the unnamed register
xnoremap <leader>p "_dP
