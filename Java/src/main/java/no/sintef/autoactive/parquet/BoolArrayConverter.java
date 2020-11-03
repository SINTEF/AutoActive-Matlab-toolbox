package no.sintef.autoactive.parquet;

public class BoolArrayConverter extends PrimitiveArrayConverter {
	protected boolean data[];

	public BoolArrayConverter(int length) {
		super(length);
		data = new boolean[length];
	}
	
	@Override
	public void addBoolean(boolean value) {
		data[index] = value;
		index++;
	}
	
	public boolean[] getData() {
		return data;
	}

}
