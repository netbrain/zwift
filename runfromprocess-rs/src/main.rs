use std::mem::{size_of, zeroed};

use windows::{
    core::PWSTR,
    Win32::{
        Foundation::{CloseHandle, ERROR_INSUFFICIENT_BUFFER, HANDLE},
        System::{
            Memory::{GetProcessHeap, HeapAlloc, HeapFree, HEAP_NONE, HEAP_ZERO_MEMORY},
            Threading::{
                CreateProcessW, DeleteProcThreadAttributeList, InitializeProcThreadAttributeList,
                OpenProcess, UpdateProcThreadAttribute, CREATE_UNICODE_ENVIRONMENT,
                EXTENDED_STARTUPINFO_PRESENT, LPPROC_THREAD_ATTRIBUTE_LIST, PROCESS_ALL_ACCESS,
                PROCESS_INFORMATION, PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, STARTF_USESHOWWINDOW,
                STARTUPINFOEXW,
            },
        },
        UI::WindowsAndMessaging::SW_SHOW,
    },
};

fn main() {
    // parse args
    let args: Vec<String> = std::env::args().collect();
    let procname = std::path::Path::new(args[0].as_str())
        .file_name()
        .unwrap()
        .to_str()
        .unwrap();

    if args.len() < 3 {
        println!("Usage: {} <ppid> <commandline>", procname);
        return;
    }

    let ppid: u32 = args[1].parse().unwrap();

    // open target process
    let phandle = unsafe { OpenProcess(PROCESS_ALL_ACCESS, false, ppid).unwrap() };

    // parent process spoofing
    unsafe {
        create_process_with_handle(phandle, &args[2..]).unwrap();
        CloseHandle(phandle).expect("Failed closing handle");
    };
}

/// # Safety
///
/// Unsafe
pub unsafe fn create_process_with_handle(
    handle: HANDLE,
    args: &[String],
) -> Result<u32, windows::core::Error> {
    let mut si: STARTUPINFOEXW = zeroed();
    let mut pi: PROCESS_INFORMATION = zeroed();
    let mut size: usize = 0x30;

    loop {
        if size > 1024 {
            return Err(windows::core::Error::from_win32());
        }

        si.StartupInfo.cb = size_of::<STARTUPINFOEXW>() as u32;
        si.lpAttributeList = LPPROC_THREAD_ATTRIBUTE_LIST(HeapAlloc(
            GetProcessHeap().unwrap(),
            HEAP_ZERO_MEMORY,
            size,
        ));

        if si.lpAttributeList.is_invalid() {
            return Err(windows::core::Error::from_win32());
        }
        let ret = match InitializeProcThreadAttributeList(si.lpAttributeList, 1, 0, &mut size) {
            Ok(()) => {
                UpdateProcThreadAttribute(
                    si.lpAttributeList,
                    0,
                    PROC_THREAD_ATTRIBUTE_PARENT_PROCESS as usize,
                    Some(&handle as *const _ as *mut _),
                    size_of::<HANDLE>(),
                    None,
                    None,
                )?;

                si.StartupInfo.dwFlags = STARTF_USESHOWWINDOW;
                si.StartupInfo.wShowWindow = SW_SHOW.0 as _;

                let mut cmdline: Vec<_> = args.join(" ").encode_utf16().collect();
                cmdline.push(0x0);

                // println!("CMD len {}", cmdline.len());

                CreateProcessW(
                    None,
                    PWSTR::from_raw(cmdline.as_mut_ptr()),
                    None,
                    None,
                    false,
                    CREATE_UNICODE_ENVIRONMENT | EXTENDED_STARTUPINFO_PRESENT,
                    None,
                    None,
                    &si.StartupInfo,
                    &mut pi,
                )?;

                CloseHandle(pi.hThread)?;
                CloseHandle(pi.hProcess)?;

                Ok(pi.dwProcessId)
            }
            // Err(windows::core::Error::from(ERROR_INSUFFICIENT_BUFFER)) => {}
            Err(e) => {
                if e != windows::core::Error::from(ERROR_INSUFFICIENT_BUFFER) {
                    Err(e)
                } else {
                    Ok(0)
                }
            }
        };

        if !si.lpAttributeList.is_invalid() {
            DeleteProcThreadAttributeList(si.lpAttributeList);
        }
        HeapFree(
            GetProcessHeap().unwrap(),
            HEAP_NONE,
            Some(si.lpAttributeList.0),
        )?;

        match ret {
            Ok(0) => {
                continue;
            }
            Ok(pid) => {
                return Ok(pid);
            }
            Err(e) => {
                return Err(e);
            }
        }
    }
}
