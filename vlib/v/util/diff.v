module util

import v.util.diff

// compare_files returns a string displaying the differences between two strings.
pub fn compare_files(path1 string, path2 string) !string {
	return diff.compare_files(path1, path2)
}

// compare_text returns a string displaying the differences between two strings.
pub fn compare_text(text1 string, text2 string) !string {
	return diff.compare_text(text1, text2)
}

// find_working_diff_command returns the first available command from a list of known diff cli tools.
@[deprecated]
@[deprecated_after: '2024-05-31']
pub fn find_working_diff_command() !string {
	return diff.find_working_diff_command()
}

// color_compare_files returns a colored diff between two files.
@[deprecated: 'use `compare_files` instead']
@[deprecated_after: '2024-05-31']
pub fn color_compare_files(diff_cmd string, path1 string, path2 string) string {
	return diff.color_compare_files(diff_cmd, path1, path2)
}

// color_compare_strings returns a colored diff between two strings.
@[deprecated: 'use `compare_text` instead']
@[deprecated_after: '2024-05-31']
pub fn color_compare_strings(diff_cmd string, unique_prefix string, expected string, found string) string {
	return diff.color_compare_strings(diff_cmd, unique_prefix, expected, found)
}
