/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package no.sintef.autoactive.parquet;

import org.apache.parquet.io.api.Binary;

/**
 *
 * @author kasperb
 */
public class BinaryArrayConverter extends PrimitiveArrayConverter {
    protected String data[];

    public BinaryArrayConverter(int length) {
    	super(length);
	data = new String[length];
    }
    
    public void addBinary(Binary value){
        String tempString = new String(value.getBytes());
        data[index] = tempString;
        index ++;
    }
    
    public String[] getData(){
        return data;
    }
    
    
}
