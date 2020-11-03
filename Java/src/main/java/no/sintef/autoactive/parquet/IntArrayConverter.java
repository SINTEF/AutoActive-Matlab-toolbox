package no.sintef.autoactive.parquet;

public class IntArrayConverter extends PrimitiveArrayConverter {
	protected int data[];

	public IntArrayConverter(int length) {
		super(length);
		data = new int[length];
	}
	
	@Override
	public void addInt(int value) {
		data[index] = value;
		index++;
	}
	
	public int[] getData() {
		return data;
	}
}
