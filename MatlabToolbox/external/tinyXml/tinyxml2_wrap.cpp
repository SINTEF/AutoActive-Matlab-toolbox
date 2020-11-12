/*
 *   XML serializing/deserializing of MATLAB arrays
 *   author: Ladislav Dobrovsky   (dobrovsky@fme.vutbr.cz, ladislav.dobrovsky@gmail.com)
 *   
 *   last change: 2015-03-17
 *
 *
 *   2015-02-28     Peter van den Biggelaar    Handle structure similar to xml_load from Matlab Central
 *   2015-03-05     Ladislav Dobrovsky         Function handles load/save  (str2func, func2str) 
 *   2015-03-05     Peter van den Biggelaar    Support N-dimension arrays
 *   2015-03-06     Peter van den Biggelaar    Support complex doubles and sparse matrices
 *   2015-03-07     Peter van den Biggelaar    updated tinyxml2.h from version 0.9.4 to version 2.2.0 and add tinyxml2.cpp from https://github.com/leethomason/tinyxml2
 *   2015-03-08     Peter van den Biggelaar    0.9.0: Support int64 and uint64 classes
 *   2015-03-11     Peter van den Biggelaar    0.9.1: Support Inf and NaN
 *   2015-03-13     Peter van den Biggelaar    0.9.2: Add MsgId's; put comment after header;
 *                                             Print Inf and NaN on Unix similar as Windows       
 *   2015-03-18     Peter van den Biggelaar    0.10.0: Fix roundtrip issue with empty cell and struct elements
 *                                             Allow 'on' and 'off' for OPTIONS
 *                                             Allow name input for root element
 *   2015-03-28     Peter van den Biggelaar    0.10.1: Build with version 3.0.0 of tinyxml2.cpp from https://github.com/leethomason/tinyxml2
 *                                             Include function name when returning version number
 *   2015-04-03     Ladislav Dobrovsky         1.0.0: Refactoring
 *                                             [DISABLED, not working] base64 coding of binary data (optional)  
 */

#define MEXFUNCNAME "tinyxml2_wrap"

#define TIXML2_WRAP_MAJOR_VERSION  "1"
#define TIXML2_WRAP_MINOR_VERSION  "0"
#define TIXML2_WRAP_PATCH_VERSION  "0"


#include "tinyxml2.h"

/*
 * uncomment to fix next compilation error on 32bit Windows:  
 *      error C2371: 'char16_t' : redefinition; different basic types
 */
// #ifdef _CHAR16T
// #define CHAR16_T
// #endif

#include <mex.h>

#include <string>
#include <sstream>
#include <iostream>
#include <math.h>   // fabs

/*#include <b64/encode.h>
#include <b64/decode.h>
*/

/*
 * Assume 32 bit addressing for old Matlab
 * See MEX option "compatibleArrayDims" for MEX in Matlab >= 7.7.
 */
#ifndef MWSIZE_MAX
typedef int mwSize;
typedef int mwIndex;
#endif

// format modifier for scanning and printing size_t
#ifdef _WIN64
#define PR_SIZET "ll"
#else
#define PR_SIZET "l"
#endif

#ifdef _WIN32
#define strcasecmp(x,y) _stricmp((x),(y))
#endif

using namespace tinyxml2;
using namespace std;

#define MSGID_INPUT         MEXFUNCNAME ":InputFail"
#define MSGID_READ          MEXFUNCNAME ":ReadFail"
#define MSGID_WRITE         MEXFUNCNAME ":WriteFail"
#define MSGID_CLASSID       MEXFUNCNAME ":ClassIdFail"
#define MSGID_CALLMATLAB    MEXFUNCNAME ":CallMatlabFail"
#define MSGID_DEVEL         MEXFUNCNAME ":RuntimeError_Devel"


#include "exportoptions.h"
#include "misc_utils.h"

XMLNode * addAny(XMLNode *parent, const mxArray *data_MA, const char *nodeName, ExportOptions& options);
mxArray * extractAny(const XMLElement *element);


template<typename T>
XMLNode * add(XMLNode *parent, T const * const data, const mxArray *data_MA, mxClassID classID, const char *nodeName, ExportOptions &options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );
    
    mwSize        ndim = mxGetNumberOfDimensions(data_MA);
    const mwSize *dims = mxGetDimensions(data_MA);
    size_t       numel = mxGetNumberOfElements(data_MA);
    if(numel!=1 && options.storeSize)
    {
        char * sizeStr = Utils::createSizeStr(ndim, dims);
        element->SetAttribute("size", sizeStr);
        mxFree(sizeStr);
    }
    
    if(options.storeClass)
    {
        element->SetAttribute("type", mxGetClassName(data_MA));
    }

    /*if(options.encodeBase64)
    {
        element->SetAttribute("encoding", "base64");
    }*/
    
    const char *frmStr = Utils::getFormatingString(classID, mxGetClassName(data_MA), options.singleFloatingFormat, options.doubleFloatingFormat);
    
    if(numel)
    {    
        /*if(options.encodeBase64)
        {
            stringstream ssIn, ssOut;
            ssIn.write(reinterpret_cast<const char*>(data), sizeof(T)*numel);
            options.encode64(ssIn, ssOut);
            element->InsertFirstChild( doc->NewText(ssOut.str().c_str()) );
        }
        else*/
        {
            string str;
            static char format[256];
            sprintf(format, "%s ", frmStr);

            static char tmpS[1024];
            for(mwSize i=0; i<numel; i++)
            {
                // fill tmpS with data[i] including NaN and Inf support
                if(classID==mxDOUBLE_CLASS || classID==mxSINGLE_CLASS)
                {
                    double value = (double)data[i];     // cast to double
                    if(!mxIsFinite(value))
                    {
                        if(mxIsNaN(value))
                            sprintf(tmpS, "NaN ");
                        else if(mxIsInf(value))
                        {
                            if(value>0)
                                sprintf(tmpS, "Inf ");
                            else
                                sprintf(tmpS, "-Inf ");                            
                        }
                    }
                    else
                        sprintf(tmpS, format, data[i]);
                }
                else
                    sprintf(tmpS, format, data[i]);

                if(i+1==numel && *tmpS)
                    // remove end space from last element
                    *(tmpS+strlen(tmpS)-1) = '\0';

                str += tmpS;
            }
            // [NOTE]: although Linux supports printing NaN and Inf, the above
            // code is a factor 3 faster than using Linux sprintf. (PvdB)
            element->InsertFirstChild( doc->NewText(str.c_str()) );
        }
    }
    else
    { // empty
        element->InsertFirstChild( doc->NewText("") );
    }
    
    return element;
}


XMLNode * addStruct(XMLNode *parent, const mxArray *aStruct, const char *nodeName, ExportOptions& options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );

    mwSize        ndim = mxGetNumberOfDimensions(aStruct);
    const mwSize *dims = mxGetDimensions(aStruct);
    size_t       numel = mxGetNumberOfElements(aStruct);
    
    if(numel!=1 && options.storeSize)
    {
        char * sizeStr = Utils::createSizeStr(ndim, dims);
        element->SetAttribute("size", sizeStr);
        mxFree(sizeStr);
    }
    
    if(options.storeClass)
    {
        element->SetAttribute("type", mxGetClassName(aStruct));
    }

    if(numel==0)
        return element; // nothing to do here...

    int nFields = mxGetNumberOfFields(aStruct);
    
    XMLElement *fieldElement=0;    

    for(unsigned idx=0; idx < numel; idx++)  // loop over indexes
    {
        for(int fN = 0; fN < nFields; fN++)  // loop over fields
        {
            const char *fieldName = mxGetFieldNameByNumber(aStruct, fN);

            mxArray *field = mxGetField(aStruct, idx, fieldName);

            if(field)
            {                
                fieldElement = addAny(element, field, fieldName, options)->ToElement();
            
                if(options.storeIndexes)
                    fieldElement->SetAttribute("idx", idx+1);
            }    
        }
    }

    return element;
}


XMLNode * addCell(XMLNode *parent, const mxArray *aCell, const char *nodeName, ExportOptions& options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );
     
    mwSize        ndim = mxGetNumberOfDimensions(aCell);
    const mwSize *dims = mxGetDimensions(aCell);
    size_t       numel = mxGetNumberOfElements(aCell);

    if(numel!=1 && options.storeSize)
    {
        char * sizeStr = Utils::createSizeStr(ndim, dims);
        element->SetAttribute("size", sizeStr);
        mxFree(sizeStr);
    }
    
    if(options.storeClass)
    {
        element->SetAttribute("type", mxGetClassName(aCell));
    }
    
    if(numel==0)
        return element; // nothing to do here...

    XMLElement *cellElement=0;
    
    for(unsigned idx=0; idx < numel; idx++)
    {
        mxArray *cellValue = mxGetCell(aCell, idx);

        if(cellValue)
        {    
            cellElement = addAny(element, cellValue, "item", options)->ToElement();
        
            if(options.storeIndexes)
                cellElement->SetAttribute("idx", idx+1);
        }
    }
        
    return element;
}


XMLNode *addChar(XMLNode *parent, char const * const data, const mxArray * aString, const char *nodeName, ExportOptions& options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );

    mwSize        ndim = mxGetNumberOfDimensions(aString);
    const mwSize *dims = mxGetDimensions(aString);
    if(options.storeSize)
    {
        char * sizeStr = Utils::createSizeStr(ndim, dims);
        element->SetAttribute("size", sizeStr);
        mxFree(sizeStr);
    }
    
    if(options.storeClass)
    {
        element->SetAttribute("type", mxGetClassName(aString));
    }
    
    char *stringCopy = mxArrayToString(aString);
    
    //printf("string len = %u ; m = %u, n = %u; content=\"%c\"\n", len, (unsigned)mxGetM(aString), (unsigned)mxGetN(aString), data[0]/*string(data, len).c_str()*/);
    
    element->InsertFirstChild( doc->NewText( stringCopy ) );
    mxFree(stringCopy);
    
    return element;
}


XMLNode *addFunctionHandle(XMLNode *parent, const mxArray *fHandle, const char *nodeName, ExportOptions& options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );
    
    if(options.storeClass)
    {
        element->SetAttribute("type", mxGetClassName(fHandle));
    }
    else
    {
        mexWarnMsgIdAndTxt(MSGID_WRITE, "function handle being saved without class specification, will become a string!\n");
    }
    
    mxArray *lhs[1];
    mxArray *rhs[1] = {const_cast<mxArray*>(fHandle)};
    
    if(mexCallMATLAB(1, lhs, 1, rhs, "func2str") != 0)
        mexWarnMsgIdAndTxt(MSGID_CALLMATLAB, "converting function handle to string failed\n");           
 
	char *stringCopy=mxArrayToString(lhs[0]);
    element->InsertFirstChild( doc->NewText( stringCopy ) );
    mxFree(stringCopy);
    return element;
}


XMLNode * addComplex(XMLNode *parent, const mxArray *aComplex, const char *nodeName, ExportOptions& options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );
     
    mwSize        ndim = mxGetNumberOfDimensions(aComplex);
    const mwSize *dims = mxGetDimensions(aComplex);
    size_t       numel = mxGetNumberOfElements(aComplex);
 
    if(numel!=1 && options.storeSize)
    {
        char * sizeStr = Utils::createSizeStr(ndim, dims);
        element->SetAttribute("size", sizeStr);
        mxFree(sizeStr);
    }
    
    if(options.storeClass)
        element->SetAttribute("type", "complex");
    else
        mexWarnMsgIdAndTxt(MSGID_WRITE, "complex being saved without class specification, will become a cell array with two elements!\n");
            
    mxArray *theMatrix = mxDuplicateArray(aComplex);
    void *pr = mxGetData(theMatrix);
    void *pi = mxGetImagData(theMatrix);
    
    // add real part; temporary set imag data to NULL
    mxSetImagData(theMatrix, NULL);
    XMLElement * realElement = addAny(element, theMatrix, "item", options)->ToElement();
    if(options.storeIndexes)
        realElement->SetAttribute("idx", 1);
    
    // add imaginary part; temporary set real data point to imag data
    mxSetData(theMatrix, pi);
    XMLElement * imagElement = addAny(element, theMatrix, "item", options)->ToElement();
    if(options.storeIndexes)
        imagElement->SetAttribute("idx", 2);
    
    // restore original pointers to real and imag data and safely destroy
    mxSetData(theMatrix, pr);
    mxSetImagData(theMatrix, pi);
    mxDestroyArray(theMatrix);
        
    return element;
}    


XMLNode * addSparse(XMLNode *parent, const mxArray *aSparse, const char *nodeName, ExportOptions& options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );
    
    mwSize        ndim = mxGetNumberOfDimensions(aSparse);
    const mwSize *dims = mxGetDimensions(aSparse);
 
    if(options.storeSize)
    {
        char * sizeStr = Utils::createSizeStr(ndim, dims);
        element->SetAttribute("size", sizeStr);
        mxFree(sizeStr);
    }

    if(options.storeClass)
        element->SetAttribute("type", "sparse");
    else
        mexWarnMsgIdAndTxt(MSGID_WRITE, " sparse being saved without class specification, will become a cell array with three elements!\n");
    
    // determine indexes of nonzero values
    mxArray * plhs[3];
    mxArray * prhs[1] = {const_cast<mxArray*>(aSparse)};
    if(mexCallMATLAB(3, plhs, 1, prhs, "find") != 0)
        mexErrMsgIdAndTxt(MSGID_CALLMATLAB, "determine indexes of sparse failed");
        
    mxArray * aRows    = plhs[0];
    mxArray * aColumns = plhs[1];
    mxArray * aValues  = plhs[2];

    XMLElement * doubleElement = 0;
    
    // add row indexes
    doubleElement = addAny(element, aRows, "item", options)->ToElement();
    if(options.storeIndexes)
        doubleElement->SetAttribute("idx", 1);
    
    // add column indexes
    doubleElement = addAny(element, aColumns, "item", options)->ToElement();
    if(options.storeIndexes)
        doubleElement->SetAttribute("idx", 2);
        
    // add values
    doubleElement = addAny(element, aValues, "item", options)->ToElement();
    if(options.storeIndexes)
        doubleElement->SetAttribute("idx", 3);
             
    return element;    
}


XMLNode * addAny(XMLNode *parent, const mxArray *data_MA, const char *nodeName, ExportOptions& options)
{
    void const * const data=mxGetData(data_MA);
    mxClassID classID = mxGetClassID(data_MA);
    
    if(mxIsSparse(data_MA))   // check for sparse first, because sparse can also be complex
        return addSparse(parent, data_MA, nodeName, options);
    
    if(mxIsComplex(data_MA))
        return addComplex(parent, data_MA, nodeName, options);

    switch(classID)
    {
        case mxCELL_CLASS:     return addCell(parent,   data_MA, nodeName, options);
        case mxSTRUCT_CLASS:   return addStruct(parent, data_MA, nodeName, options);
        
        case mxLOGICAL_CLASS:  return add(parent,          (mxLogical*)data, data_MA, classID, nodeName, options);
        case mxDOUBLE_CLASS:   return add(parent,             (double*)data, data_MA, classID, nodeName, options);
        case mxSINGLE_CLASS:   return add(parent,              (float*)data, data_MA, classID, nodeName, options);
        case mxINT8_CLASS:     return add(parent,        (signed char*)data, data_MA, classID, nodeName, options);
        case mxUINT8_CLASS:    return add(parent,      (unsigned char*)data, data_MA, classID, nodeName, options);
        case mxINT16_CLASS:    return add(parent,              (short*)data, data_MA, classID, nodeName, options);
        case mxUINT16_CLASS:   return add(parent,     (unsigned short*)data, data_MA, classID, nodeName, options);
        case mxINT32_CLASS:    return add(parent,                (int*)data, data_MA, classID, nodeName, options);
        case mxUINT32_CLASS:   return add(parent,       (unsigned int*)data, data_MA, classID, nodeName, options);
        case mxINT64_CLASS:    return add(parent,          (long long*)data, data_MA, classID, nodeName, options);
        case mxUINT64_CLASS:   return add(parent, (unsigned long long*)data, data_MA, classID, nodeName, options);
        
        case mxCHAR_CLASS:     return addChar(parent, (const char * const)data,  data_MA, nodeName, options);
        
        case mxFUNCTION_CLASS: return addFunctionHandle(parent, data_MA, nodeName, options);
        
        default:
        {
            mexErrMsgIdAndTxt(MSGID_CLASSID, "unsupported class to save in xml format: %s\n", mxGetClassName(data_MA));
        }            
    }
    return NULL;
}



// string
mxArray *extractChar(const XMLElement *element)
{
    mxArray *aString = mxCreateString(element->GetText());

    const char *sizeAttribute=element->Attribute( "size" );    
    if(sizeAttribute && element->GetText())
    {
        mwSize ndim=0;
        size_t numel=0;
        mwSize *dims = Utils::getDimensions(sizeAttribute, &ndim, &numel);

        size_t len = mxGetNumberOfElements(aString);
        // reshape into specified size
        // note: character arrays may look a bit weird in the xml-file
        //       because strings are stored column-wise. This functionality
        //       is equivalent with xml_save/xml_load
        
#ifdef _WIN64        
        // TODO: Windows 64 bit has a problem with the if statement
        // Adding next dummy mexPrintf here helps!!!
        mexPrintf("");
#endif        
        if ( len != numel )
        {
            // mexPrintf("len=%lu numel=%lu s=%s\n", (size_t)len, (size_t)numel, element->GetText());
            mexErrMsgIdAndTxt(MSGID_READ, "number of characters does not match specified size");
        }
        
        mxSetDimensions(aString, dims, ndim);

        mxFree(dims);
    }
    
    return aString;
}


// structures
// mxArray *mxCreateStructMatrix(mwSize m, mwSize n, int nfields, const char **fieldnames);
mxArray *extractStruct(const XMLElement *element)
{
    mwSize ndim=0;
    size_t numel=0;
    const char *sizeAttribute=element->Attribute( "size" );
    mwSize *dims = Utils::getDimensions(sizeAttribute, &ndim, &numel);

    
    if(!sizeAttribute)
    {
        // determine size by counting children and checking "idx" attribute
        numel=0;
        const XMLElement *structElement = element->FirstChildElement();
        
        while(structElement)
        {
            unsigned idx=(unsigned)numel+1;
            structElement->QueryUnsignedAttribute("idx", &idx);   // if attribute does not exists it will not change value of idx
            numel=idx;
            structElement = structElement->NextSiblingElement();
        }
        dims[0] = 1;                // 1 row
        dims[1] = (mwSize)numel;    // numel columns
    }
       
    mxArray *theStruct = mxCreateStructArray(ndim, dims, 0, 0);
    mxFree(dims);
	if(!theStruct)
        mexErrMsgIdAndTxt(MSGID_READ, "creating structure array failed.");
    
    if(numel)
    {
        unsigned *idx = NULL;
        unsigned max_idx = 1;
        const XMLElement *structElement=element->FirstChildElement();
        while(structElement)
        {
            const char *name = structElement->Value();
            if(!name)
                name="NO_NAME_STRUCT_FIELD";

            // add fieldname or increment idx for existing fieldname
            int fieldNumber = mxGetFieldNumber(theStruct, name);
            if(fieldNumber<0)
            {   // field does not exist; add field and initialize idx for this field
                fieldNumber=mxAddField(theStruct, name);
                if(fieldNumber<0)
                    mexErrMsgIdAndTxt(MSGID_READ, "can't add field");
                
                // (re)allocate space for tracking indexes for each field
                idx = (unsigned *)mxRealloc(idx, sizeof(unsigned)*(fieldNumber+1));
                idx[fieldNumber] = 1;
            }
            else
            {   // fieldname already exists
                
                // increment idx of this field
                idx[fieldNumber]++;
                    
                //  keep track of maximum idx
                if(idx[fieldNumber]>max_idx)
                    max_idx = idx[fieldNumber];
            }
            
            // get value of "idx" attribute. idx will be unchanged when attribute is not defined
            structElement->QueryUnsignedAttribute("idx", &(idx[fieldNumber]));
            if(idx[fieldNumber]>numel)
                mexErrMsgIdAndTxt(MSGID_READ, "element idx > struct length");

            // set field value
            mxArray *fieldValue = extractAny(structElement);
            if(fieldValue)   
                mxSetFieldByNumber(theStruct, idx[fieldNumber]-1, fieldNumber, fieldValue); 
            else
                mexWarnMsgIdAndTxt(MSGID_READ, "struct field %s (idx %d) is corrupted\n", name, idx[fieldNumber]);

            structElement = structElement->NextSiblingElement();
        }

        if(max_idx<numel && !sizeAttribute)
        {
            // remove extra columns
            mxSetN(theStruct, max_idx);
        }
        
        mxFree(idx);
    }

    return theStruct;
}


// cells
mxArray *extractCell(const XMLElement *element)
{
    mwSize ndim=0;
    size_t numel=0;
    const char *sizeAttribute=element->Attribute( "size" );
    mwSize *dims = Utils::getDimensions(sizeAttribute, &ndim, &numel);

    // count cells
    if(!sizeAttribute)
    {
        unsigned len2=0;
        const XMLElement *cellElement = element->FirstChildElement("item");
        while(cellElement)
        {
            unsigned idx=len2+1; // idx range: 1...N
            cellElement->QueryUnsignedAttribute("idx", &idx);
            len2++;
            if(idx>len2+1)
                len2=idx;
            cellElement = cellElement->NextSiblingElement("item");
        }
        if(numel != len2)
        {           
            ndim    = 2;
            dims[0] = 1;
            dims[1] = len2;
            numel   = len2;
            if(sizeAttribute)
                mexWarnMsgIdAndTxt(MSGID_READ, "cell array size specified, but the actual count differs\n");
        }
    }

    mxArray *theCell = mxCreateCellArray(ndim, dims);
    mxFree(dims);

    if(numel)
    {
        unsigned naturalOrder=0; // used if idx is not specified
        const XMLElement *cellElement = element->FirstChildElement("item");
        while(cellElement)
        {
            unsigned idx=naturalOrder+1; // idx range: 1...N
            cellElement->QueryUnsignedAttribute("idx", &idx);

            if(idx>numel)
                mexErrMsgIdAndTxt(MSGID_READ, "element idx > cell length");

            mxArray *cellValue = extractAny(cellElement);
            if(cellValue)
                mxSetCell(theCell, idx-1, cellValue);
            else
                mexWarnMsgIdAndTxt(MSGID_READ, "cell (idx %d) is corrupted\n", idx);

            cellElement = cellElement->NextSiblingElement("item");
            naturalOrder++; 
        }
    }
       
    return theCell;	
}


template <typename T>
mxArray *extract(const XMLElement *element, mxClassID classID)
{
    mwSize ndim=0;
    size_t numel=0;
    const char *sizeAttribute=element->Attribute( "size" );
    mwSize *dims = Utils::getDimensions(sizeAttribute, &ndim, &numel);
    
    if(!sizeAttribute)
    {
        // count words to determine number of values
        const char *p = element->GetText();
        numel = 0;
        while(*p)
        {
            while(*p &&  isspace(*p)) p++;  // find next non-space
            if(*p)                          // at begin of word
                numel++;                    
            while(*p && !isspace(*p)) p++;  // find next space
        }    
        dims[0] = 1;                        // return row vector
        dims[1] = numel;      
    }       
      
    mxArray *theMatrix = mxCreateNumericArray(ndim, dims, classID, mxREAL);    
    mxFree(dims);

    if(numel)
    {
        T *data = (T*)mxGetData(theMatrix);
        stringstream ss(element->GetText());
        for(mwIndex idx=0; idx<numel; idx++)
        {
            if(classID == mxINT8_CLASS || classID == mxUINT8_CLASS)
            { // code path for 8bit integer number (char)
                int value;
                ss >> value; // string stream would extract ASCII value of a character, not whole number
                data[idx] = (T)(value);
            }
            else
            {    
                ss >> data[idx];
            }
            
            if(!ss.good())
            {   // something went wrong   
                if(ss.eof() && idx+1!=numel)
                {    
                    mexWarnMsgIdAndTxt(MSGID_READ, "specified size is larger than available number of data elements eof=%d, badbit=%d\n", (int)ss.eof(), (int)ss.bad());
                    break;
                }    
                
                if(ss.fail())
                {   // check for NaN and Inf with optional sign
                    ss.clear();
                    bool negSign = false;
                    if(ss.unget())    // backup one character because sign may have been read succesfully
                    {
                        // check for sign character
                        char c;
                        ss.get(c);
                        negSign = (c=='-');                
                    }
                    else
                    {
                        // backup may fail when stream starts with "nan" or "inf"
                        ss.clear();
                    }

                    // read 3 character and check if it is "nan" or "inf"
                    char buf[4];
                    if(ss.get(buf,4))
                    {                              
                        if (!strcasecmp(buf,"nan"))
                        {
                            data[idx] = (T)mxGetNaN();
                        }
                        else if (!strcasecmp(buf,"inf"))
                        {
                            if(negSign)
                                data[idx] = (T)(-mxGetInf());
                            else
                                data[idx] = (T)mxGetInf();
                        }
                        else
                        {   // other string than "nan" or "inf"
                            mexWarnMsgIdAndTxt(MSGID_READ, "stringstream invalid number\n");
                            break;
                        }
                    }
                    else
                    {   // reading 3 characters failed --> invalid number
                        mexWarnMsgIdAndTxt(MSGID_READ, "stringstream invalid number\n");
                        break;
                    }               
                }
                
                if(ss.bad())
                {    
                    mexWarnMsgIdAndTxt(MSGID_READ, "stringstream error eof=%d, badbit=%d\n", (int)ss.eof(), (int)ss.bad());
                    break;
                }    
            }
        }

#ifndef _WIN32        
        // TODO: eofbit is not set when last character is read with ss.get on Windows
        if(!ss.eof())
            mexWarnMsgIdAndTxt(MSGID_READ, "stringstream has more data elements available than specified in size.\n");           
#endif
    }
    return theMatrix;
}


// function handle
mxArray *extractFunctionHandle(const XMLElement *element)
{
    mxArray *lhs[1], *rhs[1]={mxCreateString(element->GetText())};
    
    if(mexCallMATLAB(1, lhs, 1, rhs, "str2func") !=0 )
            mexWarnMsgIdAndTxt(MSGID_CALLMATLAB, "converting string to function handle failed\n");        
    
    return lhs[0];
}    


// complex
mxArray *extractComplex(const XMLElement *element)
{
    // read 2 child elements with real and imag values
    mxArray *aRealValue;
    mxArray *aImagValue;    
    const XMLElement *complexElement = element->FirstChildElement("item");
    
    if(complexElement)
    {
        aRealValue = extractAny(complexElement); 
        complexElement = complexElement->NextSiblingElement("item");
    }
    else // create empty Matrix
        aRealValue = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);

    if(complexElement)
    {
        aImagValue = extractAny(complexElement); 
        complexElement = complexElement->NextSiblingElement("item");
    }
    else // create empty Matrix
        aImagValue = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);

    if(complexElement)
        mexWarnMsgIdAndTxt(MSGID_READ, "extra elements in complex type ignored");
     
    // check types
    if(!mxIsNumeric(aRealValue))
        mexErrMsgIdAndTxt(MSGID_READ, "real data of sparse must be numeric");
    if(!mxIsNumeric(aImagValue))
        mexErrMsgIdAndTxt(MSGID_READ, "imaginary data of sparse must be numeric");
    
    mwSize        ndim = mxGetNumberOfDimensions(aRealValue);
    const mwSize *dims = mxGetDimensions(aRealValue);
    size_t       numel = mxGetNumberOfElements(aRealValue);

    // check sizes
    if(numel!=mxGetNumberOfElements(aImagValue))
        mexErrMsgIdAndTxt(MSGID_READ, "number of elements in real and imaginary part is different");
    if(mxGetClassID(aRealValue)!=mxGetClassID(aImagValue))
        mexErrMsgIdAndTxt(MSGID_READ, "real and imaginary part must be of the same class");
    
    mxArray * aComplex = mxCreateNumericArray(ndim, dims, mxGetClassID(aRealValue), mxCOMPLEX);

    // copy pointers to the data
    mxFree(mxGetPr(aComplex));
    mxSetPr(aComplex, mxGetPr(aRealValue));
    mxSetPr(aRealValue, NULL);
    mxDestroyArray(aRealValue);
       
    mxFree(mxGetPi(aComplex));
    mxSetPi(aComplex, mxGetPr(aImagValue));
    mxSetPr(aImagValue, NULL);
    mxDestroyArray(aImagValue);
        
    return aComplex;        
}


// sparse
mxArray *extractSparse(const XMLElement *element)
{
    mwSize ndim=0;
    size_t numel=0;
    const char *sizeAttribute=element->Attribute( "size" );
    mwSize *dims = Utils::getDimensions(sizeAttribute, &ndim, &numel);
    if(ndim>2)
        mexErrMsgIdAndTxt(MSGID_READ, "Only 2-D supported for sparse");

    // read 3 child elements with rows, colums, and values
    mxArray *aRows;
    mxArray *aColumns;
    mxArray *aValues;
    const XMLElement *sparseElement = element->FirstChildElement("item"); 
    if(sparseElement)
    {
        aRows = extractAny(sparseElement);
        sparseElement = sparseElement->NextSiblingElement("item");
    }
    else // create empty Matrix
        aRows = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);
    
    if(sparseElement)
    {
        aColumns = extractAny(sparseElement);
        sparseElement = sparseElement->NextSiblingElement("item");
    }
    else // create empty Matrix
        aColumns = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);

    if(sparseElement)
    {
        aValues = extractAny(sparseElement);
        sparseElement = sparseElement->NextSiblingElement("item");
    }
    else // create empty Matrix
        aValues = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);

    if(sparseElement)
        mexWarnMsgIdAndTxt(MSGID_READ, "extra elements in sparse type ignored");
    
    // check types
    if(mxGetClassID(aRows) != mxDOUBLE_CLASS)
        mexErrMsgIdAndTxt(MSGID_READ, "row indexes for sparse must be of type double");
    if(mxGetClassID(aColumns) != mxDOUBLE_CLASS)
        mexErrMsgIdAndTxt(MSGID_READ, "columns indexes for sparse must be of type double");
    if(mxGetClassID(aValues) != mxDOUBLE_CLASS)
        mexErrMsgIdAndTxt(MSGID_READ, "values for sparse must be of type double");

    // check sizes
    numel = mxGetNumberOfElements(aRows);
    if(numel!=mxGetNumberOfElements(aColumns))
        mexErrMsgIdAndTxt(MSGID_READ, "number of colomn indexes does not match number of row indexes");
    if(numel!=mxGetNumberOfElements(aValues))
        mexErrMsgIdAndTxt(MSGID_READ, "number of values does not match number of row indexes");

    bool isComplex = mxIsComplex(aValues);
    mxComplexity ComplexFlag = mxREAL;
    if(isComplex)
        ComplexFlag = mxCOMPLEX;
    
    mwSize m = dims[0];
    mwSize n = dims[1];  
    mxArray * aSparse = mxCreateSparse(m, n, (mwSize)numel, ComplexFlag);
    
    if(numel)
    {
        // copy data
        double * row = mxGetPr(aRows);
        double * col = mxGetPr(aColumns);
        double * pr  = mxGetPr(aValues);
        double * pi  = NULL;
    
        double * sr  = mxGetPr(aSparse);
        double * si  = NULL;
        mwIndex * irs = mxGetIr(aSparse);
        mwIndex * jcs = mxGetJc(aSparse);
    
        if(isComplex)
        {
            pi  = mxGetPi(aValues);
            si  = mxGetPi(aSparse);
        }
    
        // fill sparse array
        mwIndex k=0;
        for(mwIndex j=0; j<n; j++)
        {
            jcs[j] = k;
            while((mwIndex)(col[k])-1==j)
            {
                sr[k] = pr[k];
                if(isComplex)
                    si[k] = pi[k];
                irs[k] = (mwIndex)(row[k])-1;
                k++;
            }
        }
        jcs[n] = k;

        /*
        for(mwIndex j=0; j<numel; j++)
            printf("irs[%d]=%d\n",j,irs[j]);

        for(mwIndex j=0; j<numel; j++)
            printf("sr[%d]=%e\n",j,sr[j]);

        if(isComplex)
            for(mwIndex j=0; j<numel; j++)
                printf("si[%d]=%e\n",j,si[j]);

        for(mwIndex j=0; j<=n; j++)
            printf("jcs[%d]=%d\n",j,jcs[j]);
        */
    }

    // cleanup
    mxDestroyArray(aRows);
    mxDestroyArray(aColumns);
    mxDestroyArray(aValues);

    return aSparse;        
}
    

mxArray *extractAny(const XMLElement *element)
{
    const char* classStr = element->Attribute("type");
    
    if(!classStr)    
    {
        // have children elements -> struct or cell
        if(element->FirstChildElement())
        {           
            // we need at least 2 consequtive 'item' elements to consider the element a cell array
            const XMLElement *itemElement=element->FirstChildElement("item");
            if(itemElement && itemElement->NextSiblingElement("item"))
                classStr="cell";
            else
                // otherwise it's a struct
                classStr="struct"; 
        }
        else // or else it's considered a string
            classStr="char";
    }
    else if(strcmp(classStr,"complex")==0)
        return extractComplex(element);
    else if(strcmp(classStr,"sparse")==0)
        return extractSparse(element);
        
    mxClassID classID = Utils::getClassByName(classStr);

    switch(classID)
    {
        case mxCELL_CLASS:     return extractCell(element);
        case mxSTRUCT_CLASS:   return extractStruct(element);
        
        case mxLOGICAL_CLASS:  return extract<mxLogical>(element, classID);
        case mxDOUBLE_CLASS:   return extract<double>(element, classID);
        case mxSINGLE_CLASS:   return extract<float>(element, classID);
        case mxINT8_CLASS:     return extract<signed char>(element, classID);
        case mxUINT8_CLASS:    return extract<unsigned char>(element, classID);
        case mxINT16_CLASS:    return extract<short>(element, classID);
        case mxUINT16_CLASS:   return extract<unsigned short>(element, classID);
        case mxINT32_CLASS:    return extract<int>(element, classID);
        case mxUINT32_CLASS:   return extract<unsigned int>(element, classID);
        case mxINT64_CLASS:    return extract<long long>(element, classID);
        case mxUINT64_CLASS:   return extract<unsigned long long>(element, classID);
        
        case mxCHAR_CLASS:     return extractChar(element);
        
        case mxFUNCTION_CLASS: return extractFunctionHandle(element);
        
        default:
        {
            mexErrMsgIdAndTxt(MSGID_CLASSID, "unrecognized or unsupported class: %s", classStr);
        }
    }
    
    return NULL;  
}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    if(nlhs>1)
        mexErrMsgIdAndTxt(MSGID_INPUT, "Too many output arguments\n");
    if(nrhs<1)
        mexErrMsgIdAndTxt(MSGID_INPUT, "Not enough input arguments: " MEXFUNCNAME "(mode, ...)\n");
    
    const mxArray *mode_MA = prhs[0];
    if(!mxIsChar(mode_MA))
        mexErrMsgIdAndTxt(MSGID_INPUT, "mode must be a string\n");
    
    char * modeString = mxArrayToString(mode_MA);
    if(!modeString)
        mexErrMsgIdAndTxt(MSGID_INPUT, "mode string error\n");
    
    if(!strcmp(modeString, "save"))
    {
        if(nlhs>0)
            mexErrMsgIdAndTxt(MSGID_INPUT, "Too many output arguments\n");
        if(nrhs<3)
            mexErrMsgIdAndTxt(MSGID_INPUT, "Not enough input arguments: " MEXFUNCNAME "('save', filename, data, ...)\n");
        if(nrhs>5)
            mexErrMsgIdAndTxt(MSGID_INPUT, "Too many input arguments\n");
        
        const mxArray *filename_MA = prhs[1];
        if(!mxIsChar(filename_MA))
            mexErrMsgIdAndTxt(MSGID_INPUT, "filename must be a string\n");
        char * filename = mxArrayToString(filename_MA);
        if(!filename)
            mexErrMsgIdAndTxt(MSGID_INPUT, "filename string error\n");
        
        const mxArray *data_MA = prhs[2];
        
        ExportOptions options(nrhs>=4 ? prhs[3] : NULL); // if the fourth argument is present - pass it, else NULL

        XMLDocument doc;
        doc.InsertEndChild( doc.NewDeclaration() );
        doc.InsertEndChild( doc.NewComment( "Written using " MEXFUNCNAME " version " TIXML2_WRAP_MAJOR_VERSION "." TIXML2_WRAP_MINOR_VERSION));

        // get root name
        if(nrhs>=5)
        {
            const mxArray *name_MA = prhs[4];        
            if(!mxIsChar(name_MA))
                mexErrMsgIdAndTxt(MSGID_INPUT, "name must be a string\n");

            char * rootName = mxArrayToString(name_MA);
            addAny(&doc, data_MA, rootName, options);           
            mxFree(rootName);            
        }
        else
        {
            // default "root" name
            addAny(&doc, data_MA, "root", options);
        }
           
        doc.SaveFile(filename);
        
        mxFree(filename);
    }

    else if(!strcmp(modeString, "load"))
    {
        if(nrhs<2)
            mexErrMsgIdAndTxt(MSGID_INPUT, "Not enough input arguments: " MEXFUNCNAME "('load', filename)\n");
        if(nrhs>2)
            mexErrMsgIdAndTxt(MSGID_INPUT, "Too many input arguments\n");
        
        const mxArray *filename_MA = prhs[1];
        if(!mxIsChar(filename_MA))
            mexErrMsgIdAndTxt(MSGID_INPUT, "filename must be a string\n");
        char * filename = mxArrayToString(filename_MA);
        if(!filename)
            mexErrMsgIdAndTxt(MSGID_INPUT, "filename string error\n");
        
        XMLDocument doc;
        
        if (doc.LoadFile(filename) != XML_NO_ERROR)
        {
            mexErrMsgIdAndTxt(MSGID_READ, "failed reading file \"%s\" ; %s", doc.GetErrorStr1(), doc.GetErrorStr2());
        }
        
        const XMLElement *root = doc.FirstChildElement();
        
        if(!root && nlhs==0)
            mexWarnMsgIdAndTxt(MSGID_READ, "no XML elements found in %s\n", filename);
        
        plhs[0] = extractAny(root);
        
        mxFree(filename);
    }

    else if(!strcmp(modeString, "format"))
    {
        if(nrhs<2)
            mexErrMsgIdAndTxt(MSGID_INPUT, "Not enough input arguments: " MEXFUNCNAME "('format', data, ...)\n");
        if(nrhs>4)
            mexErrMsgIdAndTxt(MSGID_INPUT, "Too many input arguments\n");
    
        const mxArray *data_MA = prhs[1];

        ExportOptions options(nrhs>=3 ? prhs[2] : NULL); // if the fourth argument is present - pass it, else NULL

        XMLDocument doc;
        doc.InsertEndChild( doc.NewDeclaration() );
        doc.InsertEndChild( doc.NewComment( "Created using " MEXFUNCNAME " version " TIXML2_WRAP_MAJOR_VERSION "." TIXML2_WRAP_MINOR_VERSION));

        // get root name
        if(nrhs>=4)
        {
            const mxArray *name_MA = prhs[3];        
            if(!mxIsChar(name_MA))
                mexErrMsgIdAndTxt(MSGID_INPUT, "name must be a string\n");
            
            char * rootName = mxArrayToString(name_MA);
            addAny(&doc, data_MA, rootName, options);           
            mxFree(rootName);            
        }
        else
        {
            // default "root" name
            addAny(&doc, data_MA, "root", options);
        }
           
        XMLPrinter printer;
        doc.Print( &printer );
        const char *xmlString = printer.CStr();
        
        plhs[0] = mxCreateString(xmlString);    
    }
    
    else if(!strcmp(modeString, "parse"))
    {
        if(nrhs<2)
            mexErrMsgIdAndTxt(MSGID_INPUT, "Not enough input arguments: " MEXFUNCNAME "('parse', XMLstring)\n");
        if(nrhs>2)
            mexErrMsgIdAndTxt(MSGID_INPUT, "Too many input arguments\n");
        
        const mxArray *XMLstring_MA = prhs[1];
        if(!mxIsChar(XMLstring_MA))
            mexErrMsgIdAndTxt(MSGID_INPUT, "XMLstring must be a string\n");
        char * XMLstring = mxArrayToString(XMLstring_MA);    
        if(!XMLstring)
            mexErrMsgIdAndTxt(MSGID_INPUT, "XMLstring error\n");        
        
        XMLDocument doc;
        
        if (doc.Parse(XMLstring) != XML_NO_ERROR)
        {
            mexErrMsgIdAndTxt(MSGID_READ, "failed parsing XMLstring \"%s\" ; %s", doc.GetErrorStr1(), doc.GetErrorStr2());
        }
        
        const XMLElement *root = doc.FirstChildElement();
        
        if(!root && nlhs==0)
            mexWarnMsgIdAndTxt(MSGID_READ, "no XML elements found in XMLstring\n");
        
        plhs[0] = extractAny(root);
        
        mxFree(XMLstring);
    }
    
    else if(!strcmp(modeString, "version"))
    {
        if(nrhs>1)
        mexErrMsgIdAndTxt(MSGID_INPUT, "Too many input arguments\n");

        plhs[0] = mxCreateString(MEXFUNCNAME ": " TIXML2_WRAP_MAJOR_VERSION "." TIXML2_WRAP_MINOR_VERSION "." TIXML2_WRAP_PATCH_VERSION);                    
    }
    
    else
        mexErrMsgIdAndTxt(MSGID_INPUT, "unknown mode: %s\n", modeString);
    
    mxFree(modeString);
}
