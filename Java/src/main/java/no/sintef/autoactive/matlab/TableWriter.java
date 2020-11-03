package no.sintef.autoactive.matlab;

import java.io.Closeable;
import java.io.IOException;
import static java.nio.charset.StandardCharsets.UTF_8;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.hadoop.conf.Configuration;
import org.apache.parquet.bytes.ByteBufferAllocator;
import org.apache.parquet.bytes.DirectByteBufferAllocator;
import org.apache.parquet.column.ColumnDescriptor;
import org.apache.parquet.column.ColumnWriteStore;
import org.apache.parquet.column.ColumnWriter;
import org.apache.parquet.column.ParquetProperties;
import org.apache.parquet.hadoop.CodecFactory;
import org.apache.parquet.hadoop.CodecFactory.BytesCompressor;
import org.apache.parquet.hadoop.metadata.CompressionCodecName;
import org.apache.parquet.schema.MessageType;
import org.apache.parquet.schema.PrimitiveType;
import org.apache.parquet.schema.PrimitiveType.PrimitiveTypeName;
import org.apache.parquet.schema.Type;
import org.apache.parquet.schema.Type.Repetition;

import no.sintef.autoactive.files.ArchiveWriter;
import no.sintef.autoactive.files.MemoryParquetWriter;
import no.sintef.autoactive.parquet.ColumnChunkPageWriteStore;
import org.apache.parquet.io.api.Binary;
import org.apache.parquet.schema.OriginalType;

public class TableWriter implements Closeable {
	private MessageType _schema;
	private Map<String, ColumnDescriptor> _columns = new HashMap<String, ColumnDescriptor>();
	private MemoryParquetWriter _writer;
	private ColumnChunkPageWriteStore _cPageStore;
	private ColumnWriteStore _cWriteStore;
	private long _numRows;
	
	public TableWriter(String names[], String types[], long numRows) throws IOException {
		// Create schema
		List<Type> fields = new ArrayList<Type>();
		for (int i = 0; i < names.length; i++) {
                    if (types[i].equals("UTF8")){
                        fields.add(new PrimitiveType(Repetition.REQUIRED, PrimitiveTypeName.BINARY, names[i], OriginalType.UTF8));
                    }
                    else{
			fields.add(new PrimitiveType(Repetition.REQUIRED, PrimitiveTypeName.valueOf(types[i]), names[i]));
                    }
		}
		_schema = new MessageType("root", fields);
		
		// Map ColumnDescriptors to MATLAB names
		for (int i = 0; i < names.length; i++) {
			_columns.put(names[i], _schema.getColumns().get(i));
		}
		
		// Create configurations
		ParquetProperties props = ParquetProperties.builder().withAllocator(new DirectByteBufferAllocator()).build();
		Configuration conf = new Configuration(false);
		
		// Writer classes
		ByteBufferAllocator allocator = props.getAllocator();
		CodecFactory cFactory = CodecFactory.createDirectCodecFactory(conf, allocator, props.getPageSizeThreshold());
		BytesCompressor compressor = cFactory.getCompressor(CompressionCodecName.SNAPPY);
		
		_cPageStore = new ColumnChunkPageWriteStore(compressor, _schema, allocator);
		_cWriteStore = props.newColumnWriteStore(_schema, _cPageStore);
		

		_writer = MemoryParquetWriter.create(_schema);
		_writer.start();
		_writer.startBlock(numRows);
		_numRows = numRows;
	}
	
	private ColumnWriter initColumn(String name, int rows) throws IOException {
		if (rows != _numRows) {
			throw new IllegalArgumentException("Incorrect number of rows in column");
		}
		return _cWriteStore.getColumnWriter(_columns.get(name));
	}
	
	public void writeIntColumn(String name, int data[]) throws IOException {
		ColumnWriter cwriter = initColumn(name, data.length);
		for (int d : data) {
			cwriter.write(d, 1, 0);
		}
		cwriter.close();
	}
	
	public void writeLongColumn(String name, long data[]) throws IOException {
		ColumnWriter cwriter = initColumn(name, data.length);
		for (long d : data) {
			cwriter.write(d, 1, 0);
		}
		cwriter.close();
	}
	
	public void writeFloatColumn(String name, float data[]) throws IOException {
		ColumnWriter cwriter = initColumn(name, data.length);
		for (float d : data) {
			cwriter.write(d, 1, 0);
		}
		cwriter.close();
	}
	
	public void writeDoubleColumn(String name, double data[]) throws IOException {
		ColumnWriter cwriter = initColumn(name, data.length);
		for (double d : data) {
			cwriter.write(d, 1, 0);
		}
		cwriter.close();
	}
        
	public void writeStringColumn(String name, String data[]) throws IOException {
		ColumnWriter cwriter = initColumn(name, data.length);
		for (String d : data) {
			cwriter.write(Binary.fromConstantByteArray(d.getBytes(UTF_8)), 1, 0);
		}
		cwriter.close();
	}   
	
	public void close() throws IOException {
		_cWriteStore.close();
		_cPageStore.flushToFileWriter(_writer);
		_writer.endBlock();
		Map<String,String> extraData = Collections.<String,String>emptyMap();
		_writer.end(extraData);
	}
	
	public void writeToArchive(ArchiveWriter writer, String name) throws IOException {
		writer.createEntry(name, _writer.getSize(), _writer.getCrc());
		_writer.writeTo(writer);
		writer.closeEntry();
	}
}
