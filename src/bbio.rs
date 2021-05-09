use crate::Write;

pub fn decompile_cnut (file_source_path: &std::path::Path, file_target_path: &std::path::Path) -> Result<(), std::io::Error> {
	let nutcracker_path = std::env::current_dir().unwrap().join("adams_kit").join("nutcracker.exe");
	let bbsq_path = std::env::current_dir().unwrap().join("adams_kit").join("bbsq.exe"); 
	//Above two lines should be declared somewhere globaly and only once

	let temp_file_path = file_source_path.parent().unwrap().join("temp.nut");
	match std::fs::copy(&file_source_path,&temp_file_path){	//Make temprorary file to prepare for bbsq
		Ok(_) => (),
		Err(error) =>{ 
			println!("Failed to copy file: {:?}, error: {:?}", file_source_path, error);
			return Err(error);
		}
	}

	let _bbsq_out = std::process::Command::new(&bbsq_path)
									.args(&["-d", &temp_file_path.to_str().unwrap()])
									.output()
									.expect("Failed to find bbsq (has the file been moved?)");

	let _nutcracker_out = std::process::Command::new("cmd")
										  .args(&["/C", &nutcracker_path.to_str().unwrap()])
										  .args(&[&temp_file_path.to_str().unwrap(), ">", file_target_path.to_str().unwrap()])
										  .output()
										  .expect("Failed to run nutcracker.exe (has the file been moved?)");

	//println!("bbsq: {:?} nutcracker: {:?}", bbsq_out, nutcracker_out);

	match std::fs::remove_file(temp_file_path) {
				Ok(()) => (),
				Err(error) => {
					println!("Failed to delete temp.cnut: {}", error);
					return Err(error);
					}
				}

	return Ok(())
}

/*fn compile_nut(file_source_path: &std::path::Path) -> Result<(), std::io::Error> {
	let bbsq_path = std::env::current_dir().unwrap().join("adams_kit").join("bbsq.exe"); 

	let bbsq_out = std::process::Command::new(&bbsq_path)
									.args(&["-e", &file_source_path.to_str().unwrap()])
									.output()
									.expect("Failed to find bbsq (has the file been moved?)");

	println!("bbsq: {:?}", bbsq_out);

	return Ok(())
}*/

pub fn import_mod (mod_file_path: &std::path::Path, target_dir: &std::path::Path, delete_cnuts: bool) -> std::io::Result<()>{

	let imported_mod_path = target_dir.join(mod_file_path.file_stem().unwrap());

	let mut archive = match zip::ZipArchive::new(std::fs::File::open(mod_file_path)?) {
		Ok(zip) => zip,
		Err(_) => return Err(std::io::Error::new(std::io::ErrorKind::Other, "Failed to create zip")),
	};

	match archive.extract(&imported_mod_path){
		Ok(()) => (),
		Err(_) => return Err(std::io::Error::new(std::io::ErrorKind::Other, "Failed to extract zip")),
	}


	for file in walkdir::WalkDir::new(&imported_mod_path){ //Walk through all files in unzipped folder
		let file_path = file?.path().to_owned();

		if file_path.is_file() {
			if let Some(extension) = file_path.extension() {
				if extension.eq("cnut") {
					let mut file_target_path = file_path.clone();
					file_target_path.set_extension("nut");
					decompile_cnut(&file_path, &file_target_path)?;

					if delete_cnuts {
						std::fs::remove_file(file_path)?;
					}
				}
			}
		}
	}

	return Ok(())
}

pub fn export_mod (mod_source_path: &std::path::Path, target_dir: &std::path::Path, compile: bool, delete_nuts: bool) -> Result<(), std::io::Error>{
	let taros_compile = std::env::current_dir().unwrap().join("adams_kit").join("taros_masscompile.bat");
	let mut mod_target_path = target_dir.join(mod_source_path.file_stem().unwrap());
	mod_target_path.set_extension("zip");
	println!("{:?}", mod_target_path);
	let mod_target_file = std::fs::File::create(mod_target_path).unwrap();
	let mut mod_target_zip = zip::ZipWriter::new(&mod_target_file);

	if compile {
		let _compile_out = std::process::Command::new(&taros_compile.as_os_str())
									.arg(&mod_source_path.join("scripts").as_os_str())
									.output()
									.expect("Failed to find taros_masscompile.bat (has the file been moved?)");
		println!("{:#?}", _compile_out);
	}

	for walk_file in walkdir::WalkDir::new(&mod_source_path){
		let walk_file_path = walk_file.as_ref().unwrap().path();

		if walk_file_path.is_file() {

			if walk_file_path.extension().unwrap().to_os_string() != "nut" {
				mod_target_zip.start_file(walk_file_path.strip_prefix(&mod_source_path).unwrap().to_str().unwrap(),
										  zip::write::FileOptions::default())?;
				mod_target_zip.write(&std::fs::read(walk_file_path).unwrap())?;
			} else {
				if !compile || !delete_nuts {
					mod_target_zip.start_file(walk_file_path.strip_prefix(&mod_source_path).unwrap().to_str().unwrap(),
											  zip::write::FileOptions::default())?;
					mod_target_zip.write(&std::fs::read(walk_file_path).unwrap())?;
				}
			}
			if compile {
				if walk_file_path.extension().unwrap().to_os_string() == "cnut" {
					match std::fs::remove_file(&walk_file_path) {
						Ok(()) => (),
						Err(error) => return Err(error),
					}
				}
			}
		}
	}
	mod_target_zip.finish()?;

	return Ok(());
}

pub fn open_log () ->  Result<(), std::io::Error> {
	let log = dirs_next::document_dir().unwrap();
	let log = log.join("Battle Brothers").join("log.html");
	match open::that(&log.into_os_string()){
		Ok(_) => (),
		Err(error) => return Err(error),
	}

	return Ok(())
}