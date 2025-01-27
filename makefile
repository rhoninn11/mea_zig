

dev: zigBuildWeb jsWebLocal
devDkr: zigBuildWeb jsWebHost

	

run_app:
	zig build run --prefix fs

app_build:
	zig build --prefix fs

app_test:
	zig build --prefix fs test

build_wasm:
	zig build -Dwasm --prefix vite_demo/public

run_wasm:
	cd vite_demo && npx vite

jsWebHost:
	cd vite_demo && npx vite --host

npm-install:
	cd vite_demo && npm install

