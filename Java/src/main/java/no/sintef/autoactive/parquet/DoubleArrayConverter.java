package no.sintef.autoactive.parquet;

public class DoubleArrayConverter extends PrimitiveArrayConverter {
	protected double data[];

	public DoubleArrayConverter(int length) {
		super(length);
		data = new double[length];
	}
	
	@Override
	public void addDouble(double value) {
		data[index] = value;
		index++;
	}
	
	public double[] getData() {
		return data;
	}
}
