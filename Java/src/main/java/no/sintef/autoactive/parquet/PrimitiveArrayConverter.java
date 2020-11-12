package no.sintef.autoactive.parquet;

import org.apache.parquet.io.api.PrimitiveConverter;

public abstract class PrimitiveArrayConverter extends PrimitiveConverter {
	protected int size;
	protected int index;
	
	public PrimitiveArrayConverter(int length) {
		size = length;
		index = 0;
	}
}
