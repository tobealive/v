module diff

import os
import time

// TODO: windows tool
pub enum DiffTool {
	@none
	colordiff
	diff
	delta
	from_env
}

@[params]
pub struct CompareOptions {
pub:
	cmd  DiffTool
	args string
}

const default_args = $if openbsd {
	['-d', '-a', '-U', '2']
} $else $if freebsd {
	['--minimal', '--text', '--unified=2']
} $else {
	['--minimal', '--text', '--unified=2', '--show-function-line="fn "']
}

// NOTE:
// - tools: rewriete `util.diff`, deprecate current comparison functions
// - Tools like `code` and `opendiff` that won't do what the function states returning a string but
// open the file in a GUI will not be taken into account be default but only via env opts.
// - Unrecoverable errors instead of letting users handle them is imho untanable.
// - Allows other tools like `delta` which are currently unusable due to hardcoded default flags
// - Allows to specific custom options like. This is also a fix for the statement in the help message


// compare_files returns a string displaying the differences between two files.
pub fn compare_files(path1 string, path2 string, opts CompareOptions) !string {
	tool := match opts.cmd {
		.@none { find_working_diff_cmd()! }
		.from_env { os.getenv('VDIFF_TOOL') }
		else { opts.cmd.str() }
	}
	os.find_abs_path_of_executable(tool) or {
		return error('failed to find comparison command `${tool}`')
	}
	args := match true {
		opts.cmd == .from_env { os.getenv('VDIFF_OPTIONS') }
		opts.args != '' { opts.args }
		opts.cmd == .delta { '' }
		else { '' }
	}
	if args == '' && tool == 'diff' {
		// Add color option to default diff command.
		res := os.execute('${tool} --color=always ${diff.default_args.join(' ')} ${os.quoted_path(path1)} ${os.quoted_path(path2)}')
		if !res.output.starts_with('diff: unrecognized option') {
			return res.output.trim_right('\r\n')
		}
	}
	cmd := '${tool} ${args} ${os.quoted_path(path1)} ${os.quoted_path(path2)}'
	return os.execute(cmd).output.trim_right('\r\n')
}

// compare_text returns a string displaying the differences between two strings.
pub fn compare_text(text1 string, text2 string, opts CompareOptions) !string {
	ctime := time.sys_mono_now()
	tmp_dir := os.join_path_single(os.vtmp_dir(), ctime.str())
	os.mkdir(tmp_dir)!
	defer {
		os.rmdir_all(tmp_dir) or {}
	}
	path1 := os.join_path_single(tmp_dir, 'text1.txt')
	path2 := os.join_path_single(tmp_dir, 'text2.txt')
	// Add `\n` to Prevent printing `\ No newline at end of file` when comparing strings.
	// TODO: test
	os.write_file(path1, text1 + '\n')!
	os.write_file(path2, text2 + '\n')!
	return compare_files(path1, path2, opts)!
}

fn find_working_diff_cmd() !string {
	known_diff_tools := [DiffTool.colordiff, .diff]
	for tool in known_diff_tools {
		cmd := tool.str()
		os.find_abs_path_of_executable(cmd) or { continue }
		return cmd
	}
	$if windows {
		for tool in known_diff_tools {
			cmd := '${tool.str()}.exe'
			os.find_abs_path_of_executable(cmd) or { continue }
			return cmd
		}
	}
	return error('No working "diff" command found')
}

// find_working_diff_command returns the first available command from a list of known diff cli tools.
@[deprecated_after: '2024-06-30']
@[deprecated]
pub fn find_working_diff_command() !string {
	env_difftool := os.getenv('VDIFF_TOOL')
	env_diffopts := os.getenv('VDIFF_OPTIONS')
	if env_difftool != '' {
		os.find_abs_path_of_executable(env_difftool) or {
			return error('could not find specified VDIFF_TOOL `${env_difftool}`')
		}
		return '${env_difftool} ${env_diffopts}'
	}
	known_diff_tools := ['colordiff', 'gdiff', 'diff', 'colordiff.exe', 'diff.exe', 'opendiff',
		'code', 'code.cmd'] // NOTE: code.cmd is the Windows variant of the `code` cli tool
	mut diff_cmd := ''
	for cmd in known_diff_tools {
		os.find_abs_path_of_executable(cmd) or { continue }
		diff_cmd = cmd
		break
	}
	if diff_cmd == '' {
		return error('No working "diff" command found')
	}
	if diff_cmd in ['code', 'code.cmd'] {
		// Make sure the diff flag `-d` is included in any case.
		return '${diff_cmd} ${env_diffopts} -d'
	}
	// Don't add spaces to the cmd if there are no `env_diffopts`.
	return if env_diffopts != '' { '${diff_cmd} ${env_diffopts}' } else { diff_cmd }
}

// color_compare_files returns a colored diff between two files.
@[deprecated: 'use `compare_files` instead']
@[deprecated_after: '2024-06-30']
pub fn color_compare_files(diff_cmd string, path1 string, path2 string) string {
	tool := diff_cmd.all_before(' ')
	os.find_abs_path_of_executable(tool) or { return 'comparison command: `${tool}` not found' }
	if tool == 'diff' {
		// Add color option to default diff command.
		res := os.execute('${diff_cmd} --color=always ${diff.default_args.join(' ')} ${os.quoted_path(path1)} ${os.quoted_path(path2)}')
		if !res.output.starts_with('diff: unrecognized option') {
			return res.output.trim_right('\r\n')
		}
	}
	cmd := '${diff_cmd} ${diff.default_args.join(' ')} ${os.quoted_path(path1)} ${os.quoted_path(path2)}'
	return os.execute(cmd).output.trim_right('\r\n')
}

// color_compare_strings returns a colored diff between two strings.
@[deprecated: 'use `compare_text` instead']
@[deprecated_after: '2024-06-30']
pub fn color_compare_strings(diff_cmd string, unique_prefix string, expected string, found string) string {
	tmp_dir := os.join_path_single(os.vtmp_dir(), unique_prefix)
	os.mkdir(tmp_dir) or {}
	defer {
		os.rmdir_all(tmp_dir) or {}
	}
	ctime := time.sys_mono_now()
	e_file := os.join_path_single(tmp_dir, '${ctime}.expected.txt')
	f_file := os.join_path_single(tmp_dir, '${ctime}.found.txt')
	os.write_file(e_file, expected) or { panic(err) }
	os.write_file(f_file, found) or { panic(err) }
	res := color_compare_files(diff_cmd, e_file, f_file)
	return res
}
