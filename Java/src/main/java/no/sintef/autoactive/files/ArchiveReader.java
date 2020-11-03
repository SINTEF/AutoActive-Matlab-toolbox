package no.sintef.autoactive.files;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.zip.CRC32;
import java.util.zip.ZipEntry;
import java.util.zip.ZipException;

import org.apache.commons.io.IOUtils;
import org.apache.parquet.io.InputFile;
import org.apache.parquet.io.SeekableInputStream;

import org.apache.commons.compress2.archivers.zip.ZipFile;
import org.apache.commons.compress2.archivers.zip.ZipArchiveEntry;

public class ArchiveReader extends ZipFile {
	
	private Map<String, ContentPart> _files = new HashMap<String, ContentPart>();
        private Path _filepath;
        
	public ArchiveReader(String name) throws IOException {
		super(name);
                _filepath = Paths.get(name).toAbsolutePath().normalize();
		parseContents();
	}
	
	public ArchiveReader(File file) throws IOException {
		super(file);
                _filepath = Paths.get(file.getName()).toAbsolutePath().normalize();
		parseContents();
	}
	
	private void parseContents() throws ZipException {
		// Look at all files inside ZipFile, make sure they are uncompressed, and note their offset and size
		for (Enumeration<? extends ZipArchiveEntry > e = getEntries(); e.hasMoreElements(); ) {
			ZipArchiveEntry entry = e.nextElement();

                        if (entry.getMethod() != ZipEntry.STORED) {
				throw new ZipException("Cannot handle compressed Zip-files");
			}
			
                        long apacheOffset = entry.getDataOffset();
			if (!entry.isDirectory()) {
				long fileSize = entry.getCompressedSize();
				
				// Add to list of files
				_files.put(entry.getName(), new ContentPart(_filepath, apacheOffset, fileSize, entry.getCrc()));
				
			}
		}
	}
	
	public Set<String> getContents() {
		return Collections.unmodifiableSet(_files.keySet());
	}
	
	public ContentPart getContent(String name) {
		return _files.get(name);
	}
	
	public String getContentAsString(String name) throws IOException {
		ContentPart file = _files.get(name);
		if (file == null) {
			throw new FileNotFoundException("Archive has no content "+name);
		}
		return IOUtils.toString(file.newStream(), StandardCharsets.UTF_8);
	}
	
	public boolean copyContentToFile(String name, String path) throws IOException {
                // TODO: This could potentially allow compression using the normal streams
                // Create a stream to the contents in the file
                ContentPart file = _files.get(name);
                if (file == null) {
                        throw new FileNotFoundException("Archive has no content "+name);
                }
                SeekableInputStream source = file.newStream();
                // Create an output file to write to
                FileOutputStream destination = new FileOutputStream(path, false);
                // Write the contents to the output file, and calculate the checksum
                CRC32 checksum = new CRC32();
                byte[] buffer = new byte[1024*1024];
                ByteBuffer bb = ByteBuffer.wrap(buffer);
                int read = 0;
                while ((read = source.read(bb)) >= 0) {
                        checksum.update(buffer, 0, read);
                        destination.write(buffer, 0, read);
                        bb.clear();
                }
                destination.close();
                // Return whether the checksum was correct
                return file.getCRC() == checksum.getValue();
	}
	
	public boolean checkCrc(String name) throws IOException {

                ContentPart file = _files.get(name);
		if (file == null) {
			throw new FileNotFoundException("Archive has no content "+name);
		}
		SeekableInputStream source = file.newStream();
		// Read content and calculate the checksum
		CRC32 checksum = new CRC32();
		byte[] buffer = new byte[1024*1024];
                ByteBuffer bb = ByteBuffer.wrap(buffer);
		int read = 0;
		while ((read = source.read(bb)) >= 0) {
			checksum.update(buffer, 0, read);
                        bb.clear();
		}
                
		// Return whether the checksum was correct
		return file.getCRC() == checksum.getValue();
	}

	
	
	public class ContentPart implements InputFile {
		private Path _path;
		private long _offset;
		private long _size;
		private long _crc;
		
		protected ContentPart(Path path, long offset, long size, long crc) {
			_path = path;
			_offset = offset;
			_size = size;
			_crc = crc;
		}

		public long getLength() throws IOException {
			return _size;
		}
		
		public long getCRC() {
			return _crc;
		}

		public SeekableInputStream newStream() throws IOException {
			RandomAccessFile reader = new RandomAccessFile(_path.toString(), "r");
			return new ArchiveContent(reader, _offset, _size);
		}
	}

}
