

dev: zigBuildWeb jsWebLocal
devDkr: zigBuildWeb jsWebHost

	

run_app:
	zig build run --prefix fs

build_app:
	zig build --prefix fs

test_app:
	zig build --prefix fs test

run_wasm:
	cd vite_demo && npx vite

build_wasm:
	zig build -Dwasm --prefix vite_demo/public

jsWebHost:
	cd vite_demo && npx vite --host

npm-install:
	cd vite_demo && npm install

link_web_libs:
	ln -s ${PWD}/lib_web ${PWD}/vite_demo/src/lib
# could have gone recursive



