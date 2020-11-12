package no.sintef.autoactive.parquet;

public class LongArrayConverter extends PrimitiveArrayConverter {
	protected long data[];

	public LongArrayConverter(int length) {
		super(length);
		data = new long[length];
	}
	
	@Override
	public void addLong(long value) {
		data[index] = value;
		index++;
	}
	
	public long[] getData() {
		return data;
	}

}
