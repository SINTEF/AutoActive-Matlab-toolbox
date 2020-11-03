package no.sintef.autoactive.matlab;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.apache.hadoop.conf.Configuration;
import org.apache.parquet.VersionParser;
import org.apache.parquet.VersionParser.ParsedVersion;
import org.apache.parquet.VersionParser.VersionParseException;
import org.apache.parquet.bytes.BytesInput;
import org.apache.parquet.bytes.DirectByteBufferAllocator;
import org.apache.parquet.column.ColumnDescriptor;
import org.apache.parquet.column.ParquetProperties;
import org.apache.parquet.column.impl.ColumnReaderImpl;
import org.apache.parquet.column.page.PageReadStore;
import org.apache.parquet.column.page.PageReader;
import org.apache.parquet.hadoop.CodecFactory;
import org.apache.parquet.hadoop.ParquetFileReader;
import org.apache.parquet.hadoop.metadata.CompressionCodecName;
import org.apache.parquet.hadoop.metadata.FileMetaData;
import org.apache.parquet.io.api.PrimitiveConverter;

import no.sintef.autoactive.files.ArchiveReader;
import no.sintef.autoactive.parquet.BinaryArrayConverter;
import no.sintef.autoactive.parquet.BoolArrayConverter;
import no.sintef.autoactive.parquet.DoubleArrayConverter;
import no.sintef.autoactive.parquet.FloatArrayConverter;
import no.sintef.autoactive.parquet.IntArrayConverter;
import no.sintef.autoactive.parquet.LongArrayConverter;
import org.apache.parquet.schema.OriginalType;

public class TableReader {
	private ParquetFileReader _reader;
	private int _rows;
	private FileMetaData _meta;
	private ParsedVersion _writerVersion;
	private List<ColumnDescriptor> _columns;
	private List<PageReadStore> _pageStores;
	
	public TableReader(ArchiveReader.ContentPart parquetFile) throws IOException, VersionParseException {
		// Hack to fix config loading errors
		loadSnappyDecompressor();
		
		_reader = ParquetFileReader.open(parquetFile);
		_rows = (int)_reader.getRecordCount();
		_meta = _reader.getFileMetaData();
		_writerVersion = VersionParser.parse(_meta.getCreatedBy());
		_columns = _meta.getSchema().getColumns();
		_pageStores = new ArrayList<PageReadStore>();
		for (PageReadStore store = _reader.readNextRowGroup(); store != null; store = _reader.readNextRowGroup()) {
			_pageStores.add(store);
		}
	}
	
	public String[] getColumnNames() {
		List<String> names = new ArrayList<String>();
		for (ColumnDescriptor column : _columns) {
			names.add(String.join(".", column.getPath()));
		}
		return names.toArray(new String[0]);
	}
	
	private ColumnDescriptor getColumnFromPath(String path) {
		for (ColumnDescriptor column : _columns) {
			if (String.join(".", column.getPath()).equals(path)) {
				return column;
			}
		}
		throw new IllegalArgumentException("Table has no column "+path);
	}
	
	public String getColumnType(String name) {
            OriginalType logicalType = getColumnFromPath(name).getPrimitiveType().getOriginalType();
            
            if (logicalType == null){
                return getColumnFromPath(name).getPrimitiveType().getPrimitiveTypeName().name();
            }
            else{
                return logicalType.name();
            }
	}
	
	
	private void readColumn(String name, PrimitiveConverter converter) {
		ColumnDescriptor column = getColumnFromPath(name);
		
		for (PageReadStore pageStore : _pageStores) {
			PageReader pageReader = pageStore.getPageReader(column);
			
			ColumnReaderImpl reader = new ColumnReaderImpl(column, pageReader, converter, _writerVersion);
			for (long i = 0; i < reader.getTotalValueCount(); i++) {
				reader.writeCurrentValueToConverter();
				reader.consume();
			}
		}
	}
	
	public int[] getIntColumn(String name) {
		IntArrayConverter converter = new IntArrayConverter(_rows);
		readColumn(name, converter);
		return converter.getData();
	}
	
	public long[] getLongColumn(String name) {
		LongArrayConverter converter = new LongArrayConverter(_rows);
		readColumn(name, converter);
		return converter.getData();
	}
	
	public float[] getFloatColumn(String name) {
		FloatArrayConverter converter = new FloatArrayConverter(_rows);
		readColumn(name, converter);
		return converter.getData();
	}
	
	public double[] getDoubleColumn(String name) {
		DoubleArrayConverter converter = new DoubleArrayConverter(_rows);
		readColumn(name, converter);
		return converter.getData();
	}
	
	public boolean[] getBoolColumn(String name) {
		BoolArrayConverter converter = new BoolArrayConverter(_rows);
		readColumn(name, converter);
		return converter.getData();
	}
        
        public String[] getStringColumn(String name){
                BinaryArrayConverter converter = new BinaryArrayConverter(_rows);
                readColumn(name, converter);
                return converter.getData();
        }
	
	/* --- Ugly hack to suppress Hadoop Config errors --- */
	// MATLAB comes with another version of Woodstox then what this version of Hadoop expects
	// This causes a NoSuchMethodError, when trying to load/parse some default XML configuration
	// The default configuration is not needed, so to suppress this error, we catch it silently below
	private static boolean hasLoadedSnappyDecompressor = false;
	private static void loadSnappyDecompressor() {
		if (!hasLoadedSnappyDecompressor) {
			try {
				ParquetProperties props = ParquetProperties.builder().withAllocator(new DirectByteBufferAllocator()).build();
				Configuration config = new Configuration(true);
				CodecFactory factory = CodecFactory.createDirectCodecFactory(config, props.getAllocator(), props.getPageSizeThreshold());
				factory.getDecompressor(CompressionCodecName.SNAPPY).decompress(BytesInput.empty(), 0);
			} catch (NoSuchMethodError e) {} catch (IOException e) {}
		}
		hasLoadedSnappyDecompressor = true;
	}
}
