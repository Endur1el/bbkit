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

	crate::cli_export(original_path.to_str(), test_data_path.to_str(), false, false);
	let left = get_hash(&test_data_path.join("mod_EIMO.zip")).unwrap();
	let right = get_hash(&out_path).unwrap();
	fs::remove_file(&out_path).unwrap();
	assert_eq!(left, right);

	crate::cli_export(original_path.to_str(), test_data_path.to_str(), true, false);
	let left = get_hash(&test_data_path.join("mod_EIMO_c.zip")).unwrap();
	let right = get_hash(&out_path).unwrap();
	fs::remove_file(&out_path).unwrap();
	assert_eq!(left, right);

	crate::cli_export(original_path.to_str(), test_data_path.to_str(), true, true);
	let left = get_hash(&test_data_path.join("mod_EIMO_c_r.zip")).unwrap();
	let right = get_hash(&out_path).unwrap();
	fs::remove_file(&out_path).unwrap();
	assert_eq!(left, right);
	
}

/*#[test]
fn test_decompile() {
	let test_data_path = std::env::current_dir().unwrap().join("test_data");
	let unzip_path = test_data_path.join("mod_EIMO_unzip");

	let mut mod_dir = test_data_path.join("mod_EIMO.zip");
	crate::cli_import(mod_dir.to_str(), test_data_path.to_str(), false);
	let left = get_hash(&mod_dir).unwrap();
	mod_dir = test_data_path.join(mod_dir.file_stem().unwrap());
	let right = get_hash(&mod_dir).unwrap();
	fs::remove_file(&mod_dir).unwrap();
	assert_eq!(left, right);
}*/