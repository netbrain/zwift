{
  pkgs,
  fenix,
  naersk,
}:
let
  # Get the Windows cross-compilation toolchain from fenix
  toolchain = fenix.combine [
    fenix.stable.rustc
    fenix.stable.cargo
    fenix.targets.x86_64-pc-windows-gnu.stable.rust-std
  ];

  # Create naersk with the cross-compilation toolchain
  naersk' = naersk.override {
    cargo = toolchain;
    rustc = toolchain;
  };

  # MinGW cross-compiler
  mingw = pkgs.pkgsCross.mingwW64;
  mingwCC = mingw.stdenv.cc;

  # Get pthreads by allowing unsupported system
  pthreads = mingw.windows.pthreads.overrideAttrs (old: {
    meta = old.meta // { platforms = pkgs.lib.platforms.all; };
  });
in
naersk'.buildPackage {
  pname = "runfromprocess-rs";
  version = "unstable";

  src = pkgs.fetchFromGitHub {
    owner = "quietvoid";
    repo = "runfromprocess-rs";
    rev = "a3d003c07d1bd11ff93c4cac96d2c3aa5deb8471";
    hash = "sha256-tEmg1sFIJmWZfLLLcOmcLk0SSxgfnPBUtvkhnddfx98=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    mingwCC
  ];

  CARGO_BUILD_TARGET = "x86_64-pc-windows-gnu";

  # Tell cargo to use mingw linker for Windows target
  CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER =
    "${mingwCC}/bin/${mingwCC.targetPrefix}gcc";

  # Add pthread library path
  CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS = "-L native=${pthreads}/lib";

  # Don't run tests (they're for Windows)
  doCheck = false;

  # Copy the Windows executable to the output
  postInstall = ''
    mkdir -p $out/bin
    cp target/x86_64-pc-windows-gnu/release/runfromprocess-rs.exe $out/bin/
  '';
}
