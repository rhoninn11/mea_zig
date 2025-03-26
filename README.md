## Project for reducing zig "skill issues"

for GL 'apt install libgl-dev'
for stable lsp zls 0.13.0 branch

download zig
add zig to PATH
clone zigup
build zigup
add zigup to PATH
remove zig from PATH
intall right zig version
build proj
clone zls
checkout to right version

install node lts

ln -s $PWD/lib_web/ $PWD/vite_demo/src/lib

zig build -Dalt --prefix web_demo/prebuilt
python3 -m http.server

### Lets goooo:
No dobra myślę, że po trzech miesiącach mam już takie mniej więcej rozeznanie
co jest możliwe w tym języku jeżeli chodzi o aplikację działającą na systemie
operacyjnym.

On nawet się szybko kompiluje tej, a ja myślałem, że to będzie więcej zajmowało

### Co teraz:
Wyszło, że raylib w wersji 5.5-dev nie za bardzo pozwala na generowanie mesh'y...
A natomiast zmiana na 5.5 psuje dotychczasowy kod, ale niby autor napisał, że testowane na zigu 0.14.
Tak więc jest opcja, aby na nowej wersji zadziałało, generowanie meshy jak i budowanie projektu
(bez tego dziwnego błędu z wywoływanie zewnentrznych funkcji w comptime)
Oh boy, instanced rendering też jest jakiś walnięty, nie przyjmuje poprawnie Matriału...
