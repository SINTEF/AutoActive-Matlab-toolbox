package no.sintef.autoactive.files;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.charset.StandardCharsets;
import java.util.zip.CRC32;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public class ArchiveWriter extends ZipOutputStream {
	
	public ArchiveWriter(String name) throws IOException {
		super(new FileOutputStream(name));
		setMethod(ZipEntry.STORED);
	}
	
	public ArchiveWriter(File file) throws IOException {
		super(new FileOutputStream(file));
		setMethod(ZipEntry.STORED);
	}
	
	public ZipEntry createEntry(String name, long size, long crc) throws IOException {
		ZipEntry entry = new ZipEntry(name);
		entry.setMethod(ZipEntry.STORED);
		entry.setSize(size);
		entry.setCrc(crc);
		putNextEntry(entry);
		return entry;
	}
	
	public void writeContentFromString(String name, String content) throws IOException {
		// Get the UTF8 bytes and calculate checksum
		byte bytes[] = content.getBytes(StandardCharsets.UTF_8);
		CRC32 checksum = new CRC32();
		checksum.update(bytes);
		// Write data into the ZIP
		createEntry(name, bytes.length, checksum.getValue());
		write(bytes);
		closeEntry();
	}
	
	public void writeContentFromFile(String name, String path) throws IOException {
		// TODO: This could potentially allow compression using the normal streams
		RandomAccessFile source = new RandomAccessFile(path, "r");
		// Read the file once to calculate the checksum
		CRC32 checksum = new CRC32();
		byte[] buffer = new byte[1024*1024];
		int read = 0;
		while ((read = source.read(buffer)) >= 0) {
			checksum.update(buffer, 0, read);
		}
		// Create the entry in the ZIP
		createEntry(name, source.length(), checksum.getValue());
		// Read through the file once more to store the actual data
		source.seek(0);
		while ((read = source.read(buffer)) >= 0) {
			write(buffer, 0, read);
		}
		// Close entry and source file
		closeEntry();
		source.close();
	}
	
	
	@Override
	public void close() throws IOException {
		finish();
		super.close();
	}
}
