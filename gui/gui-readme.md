# How to use Z-Ant GUI

## Option 1: Compile and run Z-Ant GUI natively on your machine

1) Install the latest [Zig compiler](https://ziglang.org/learn/getting-started/)

2) Install [SDL3](https://github.com/libsdl-org/SDL/releases)

3) Open the Z-Ant directory

4) Run the terminal command `zig build gui`

Once compiled, you can access Z-Ant features from the GUI. To reopen the GUI, from the Z-Ant directory run the terminal command `zig-out/bin/gui`.

In the future the future Z-Ant GUI will be pre-compiled as a single package for the major operating systems, with SDL3 included as a dependency, removing the need for these steps.

## Option 2: Compile Z-Ant GUI WASM and run from a http server

1) Install the latest [Zig compiler](https://ziglang.org/learn/getting-started/)

3) Open the Z-Ant directory

4) Run the terminal command `zig build gui-wasm`

5) Start a web server from the Z-Ant/zig-out/bin directory, for example with `python3 -m http.server {port}`, and access it from a browser with the address [http://localhost:{port}](http://localhost:8000)

In the future the future Z-Ant GUI WASM will be availalbe as a standalone web app, were all processing and code generation happens on device.