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

zig build -Dalt --prefix web_demo/prebuilt
python3 -m http.server
