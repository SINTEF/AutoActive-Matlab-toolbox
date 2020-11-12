package no.sintef.autoactive.files;

import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;

import org.apache.parquet.io.SeekableInputStream;

public class ArchiveContent extends SeekableInputStream {
	private RandomAccessFile _file;
	private long _offset;
	private long _size;
	
	public ArchiveContent(RandomAccessFile file, long offset, long size) throws IOException {
		_file = file;
		_offset = offset;
		_size = size;
		_file.seek(_offset);
	}

	@Override
	public long getPos() throws IOException {
		return _file.getFilePointer()-_offset;
	}
	
	@Override
	public void seek(long pos) throws IOException {
		long actualPos = _offset;
		if (pos >= _size) actualPos += _size;
		else if (pos > 0) actualPos += pos;
		_file.seek(actualPos);
	}
	
	@Override
	public int read() throws IOException {
		if (getPos() >= _size) return -1;
		else return _file.read();
	}
	
	private int maxToRead(int bufferLength) throws IOException {
		if (getPos() >= _size) return -1;
		long leftInFile = _size - getPos();
                int minVal = bufferLength;
                if(minVal > leftInFile)
                    minVal = (int)leftInFile;
		return minVal;
	}
	
	
	
	@Override
	public void readFully(byte[] bytes) throws IOException {
		readFully(bytes, 0, bytes.length);
	}

	@Override
	public void readFully(byte[] bytes, int start, int length) throws IOException {
		int maxRead = maxToRead(length);
		if (maxRead > 0) {
			_file.readFully(bytes, start, maxRead);
		}
	}
	
	private int readIntoBuffer(ByteBuffer buf, boolean fully) throws IOException {
		int maxRead = maxToRead(buf.remaining());
		if (maxRead <= 0) return maxRead;
		
		int read = 0;
		if (buf.hasArray()) {
			// Read directly into original buffer
			byte buffer[] = buf.array();
			if (fully) {
				_file.readFully(buffer, buf.arrayOffset()+buf.position(), maxRead);
				read = maxRead;
			} else {
				read = _file.read(buffer, buf.arrayOffset()+buf.position(), maxRead);
			}
			if (read > 0) {
				buf.position(buf.position()+read);
			}
		} else {
			// Read into temporary buffer
			byte buffer[] = new byte[maxRead];
			if (fully) {
				_file.readFully(buffer);
				read = maxRead;
			} else { 
				read = _file.read(buffer);
			}
			if (read > 0) {
				buf.put(buffer, 0, read);
			}
		}
		return read;
	}

	@Override
	public int read(ByteBuffer buf) throws IOException {
		return readIntoBuffer(buf, false);
	}
	
	@Override
	public void readFully(ByteBuffer buf) throws IOException {
		readIntoBuffer(buf, true);
	}
}
