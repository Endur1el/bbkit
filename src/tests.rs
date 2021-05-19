use crate::Path;
use blake2::{Blake2b, Digest};
use std::fs;
use crate::Result;

fn get_file_hash(file_path: &Path) -> Result<String> {
	let mut hash = Blake2b::new();
	let file = fs::read(file_path)?;
	hash.update(file);
	Ok(format!("{:x}", hash.finalize()))
}

fn get_zip_hash(zip_path: &Path) -> Result<String> {
	let mut archive = zip::ZipArchive::new(std::fs::File::open(zip_path)?)?;
	let mut hash = Blake2b::new();
	for i in 0..archive.len() {
		let mut file = archive.by_index(i)?;
		let mut contents: Vec<u8> = Vec::new();
		std::io::copy(&mut file, &mut contents)?;
		hash.update(contents);
	}
	Ok(format!("{:x}", hash.finalize()))
}

fn get_hash(file_or_folder_path: &Path) -> Result<String> {
	if file_or_folder_path.is_file() {
		if file_or_folder_path.extension().unwrap().to_os_string() == "zip" {return get_zip_hash(file_or_folder_path)}
		return get_file_hash(file_or_folder_path)
	}
	let mut hash = Blake2b::new();
	for file in walkdir::WalkDir::new(&file_or_folder_path){
		let file = file?.path().to_owned();
		if file.is_dir() {continue;}
		hash.update(get_file_hash(&file)?);
	}
	Ok(format!("{:x}", hash.finalize())) 
}

#[test]
fn test_compile() {
	let test_data_path = std::env::current_dir().unwrap().join("test_data");
	let original_path = test_data_path.join("mod_EIMO_original");
	let mut out_path = original_path.clone();
	out_path.set_extension("zip");

	let run_test = |f: &str, c: bool, r: bool| {
		crate::cli_export(original_path.to_str(), test_data_path.to_str(), c, r);
		let left = get_hash(&test_data_path.join(f)).unwrap();
		let right = get_hash(&out_path).unwrap();
		fs::remove_file(&out_path).unwrap();
		assert_eq!(left, right);
	};

	run_test("mod_EIMO.zip", false, false);
	run_test("mod_EIMO_c.zip", true, false);
	run_test("mod_EIMO_c_r.zip", true, true);	
}

#[test]
fn test_decompile() {
	let test_data_path = std::env::current_dir().unwrap().join("test_data");

	let run_test = |in_f: &str, zip_f: &str, k: bool| {
		let unzip_path = test_data_path.join(in_f);
		let mut mod_dir = test_data_path.join(zip_f);
		crate::cli_import(mod_dir.to_str(), test_data_path.to_str(), k);
		let left = get_hash(&unzip_path).unwrap();
		mod_dir = test_data_path.join(mod_dir.file_stem().unwrap());
		let right = get_hash(&mod_dir).unwrap();
		fs::remove_dir_all(&mod_dir).unwrap();
		assert_eq!(left, right);
	};

	run_test("mod_EIMO_original", "mod_EIMO.zip", false);
	run_test("mod_EIMO_original", "mod_EIMO.zip", true);
	
	run_test("mod_EIMO_original", "mod_EIMO_c.zip", false);
	run_test("mod_EIMO_unzip_c_k", "mod_EIMO_c.zip", true);

	run_test("mod_EIMO_unzip_c_r", "mod_EIMO_c_r.zip", false);
	run_test("mod_EIMO_unzip_c_r_k", "mod_EIMO_c_r.zip", true);
}