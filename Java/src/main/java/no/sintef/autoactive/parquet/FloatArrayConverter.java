package no.sintef.autoactive.parquet;

public class FloatArrayConverter extends PrimitiveArrayConverter {
	protected float data[];

	public FloatArrayConverter(int length) {
		super(length);
		data = new float[length];
	}
	
	@Override
	public void addFloat(float value) {
		data[index] = value;
		index++;
	}
	
	public float[] getData() {
		return data;
	}
}
