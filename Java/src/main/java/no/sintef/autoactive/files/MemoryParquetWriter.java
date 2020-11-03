package no.sintef.autoactive.files;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.zip.CRC32;

import org.apache.parquet.hadoop.ParquetFileWriter;
import org.apache.parquet.io.OutputFile;
import org.apache.parquet.io.PositionOutputStream;
import org.apache.parquet.schema.MessageType;

public class MemoryParquetWriter extends ParquetFileWriter {
	MemoryOutputFile _buffer;

	private MemoryParquetWriter(MemoryOutputFile buffer, MessageType schema) throws IOException {
		super(buffer, schema, Mode.CREATE, 0, 0); // TODO: Block-size instead of zeros?
		_buffer = buffer;
	}
	
	public static MemoryParquetWriter create(MessageType schema) throws IOException {
		return new MemoryParquetWriter(new MemoryOutputFile(), schema);
	}
	
	public int getSize() {
		return _buffer.getSize();
	}
	
	public long getCrc() {
		return _buffer.getCrc();
	}
	
	public void writeTo(OutputStream dst) throws IOException {
		_buffer.writeTo(dst);
	}
	
	private static class MemoryOutputFile implements OutputFile {
		private CRC32 _crc = new CRC32();
		private ByteArrayOutputStream _out = new ByteArrayOutputStream();

		public PositionOutputStream create(long blockSizeHint) throws IOException {
			return new MemPosOutStream(_crc, _out);
		}

		public PositionOutputStream createOrOverwrite(long blockSizeHint) throws IOException {
			// TODO Is this OK? Seems so...
			return create(blockSizeHint);
		}

		public boolean supportsBlockSize() {
			// TODO Is this OK? Seems so...
			return false;
		}

		public long defaultBlockSize() {
			// TODO Is this OK? Seems so...
			return 0;
		}
		
		public int getSize() {
			return _out.size();
		}
		
		public long getCrc() {
			return _crc.getValue();
		}
		
		public void writeTo(OutputStream dst) throws IOException {
			_out.writeTo(dst);
		}
		
		private class MemPosOutStream extends PositionOutputStream {
			private CRC32 _crc;
			private ByteArrayOutputStream _out;
			
			public MemPosOutStream(CRC32 crc, ByteArrayOutputStream out) {
				_crc = crc;
				_out = out;
			}

			@Override
			public long getPos() throws IOException {
				return _out.size();
			}

			@Override
			public void write(int b) throws IOException {
				_out.write(b);
				_crc.update(b);
			}
		}
	}
}
