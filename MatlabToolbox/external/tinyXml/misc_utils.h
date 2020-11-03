#pragma once

class Utils
{
public:    
    static mxClassID getClassByName(const char *name)
    {
        if(!strcmp("char", name))
            return mxCHAR_CLASS;
        else if(!strcmp("single", name))
            return mxSINGLE_CLASS;
        else if(!strcmp("double", name))
            return mxDOUBLE_CLASS;
        else if(!strcmp("struct", name))
            return mxSTRUCT_CLASS;
        else if(!strcmp("cell", name))
            return mxCELL_CLASS;
        else if(!strcmp("int8", name))
            return mxINT8_CLASS;
        else if(!strcmp("uint8", name))
            return mxUINT8_CLASS;
        else if(!strcmp("int16", name))
            return mxINT16_CLASS;
        else if(!strcmp("uint16", name))
            return mxUINT16_CLASS;
        else if(!strcmp("int32", name))
            return mxINT32_CLASS;
        else if(!strcmp("uint32", name))
            return mxUINT32_CLASS;
        else if(!strcmp("int64", name))
            return mxINT64_CLASS;
        else if(!strcmp("uint64", name))
            return mxUINT64_CLASS;
        else if(!strcmp("logical", name))
            return mxLOGICAL_CLASS;
        else if(!strcmp("function_handle", name))
            return mxFUNCTION_CLASS;

        return mxUNKNOWN_CLASS;
    }


    static const char * getFormatingString(mxClassID classID, const char *className, const char *singleFloatingFormat, const char *doubleFloatingFormat)
    {
        static char errorBuf[512];

        switch(classID)
        {
            case mxDOUBLE_CLASS: return doubleFloatingFormat ? doubleFloatingFormat : "%lg";
            case mxSINGLE_CLASS: return singleFloatingFormat ? singleFloatingFormat : "%g";
            case mxLOGICAL_CLASS:
                switch(sizeof(mxLogical))
                {
                    case sizeof(int):
                        return "%d";
                    case sizeof(char):
                        return "%hhd";
                    case sizeof(short):
                        return "%hd";
                }
            case mxINT8_CLASS: return "%hhd";
            case mxUINT8_CLASS: return "%hhu";
            case mxINT16_CLASS: return "%hd";
            case mxUINT16_CLASS: return "%hu";
            case mxINT32_CLASS: return "%d";
            case mxUINT32_CLASS: return "%u";
            case mxINT64_CLASS: return "%" FMT64 "d";
            case mxUINT64_CLASS: return "%" FMT64 "u";

            default:
                sprintf(errorBuf, "[ERROR: can't get format string for class %s]", className);
                return errorBuf;
        }
    }

    static mwSize * getDimensions(const char *sizeAttribute, mwSize *ndim, size_t *numel)
    /*
     * Get number of dimensions and size per dimension from "size" attribute in element.
     *
     * Return pointer to an array with the size of each dimension.          
     * Space for dims will be allocated and needs to be freed with mxFree
     * when not needed anymore.
     *
     * sizeAttribute : string with sizes per dimension
     * *ndim         : number of dimensions
     *                 will be at least 2 
     * *numel        : number of elements
     *
     * When size attribute equals NULL, also space will be allocated and
     * ndim=2, numel=1 and size in each dimension equals 1.
     */
    {
        *ndim = 0;
        *numel = 1;
        mwSize *dimSize = (mwSize *)mxMalloc(2*sizeof(mwSize));
        if(sizeAttribute)
        {
            // read size of each dimension until it fails
            const char * size_ptr = sizeAttribute;
            int pos;
            int r;
            size_t size;

            while( (r=sscanf(size_ptr, "%" PR_SIZET "u%n", &size, &pos))>0 )    
            {
                size_ptr += pos;
                (*ndim)++;
                if(*ndim>2)            
                    dimSize = (mwSize *)mxRealloc(dimSize, *ndim * sizeof(mwSize));
                dimSize[*ndim-1] = (mwSize)size;
                *numel *= size;
            }

            if(r!=EOF)
                // scanning sizeAttribute stopped on error
                mexErrMsgIdAndTxt(MSGID_READ, "size attribute corrupted");  

            if(*ndim==0)
                mexErrMsgIdAndTxt(MSGID_READ, "size attribute was empty");

            if(*ndim==1)
            {
                // if only one dimension size is specified return a row vector
                dimSize[1] = dimSize[0];
                dimSize[0] = 1;
                *ndim = 2;
            }    
        }
        else
        {
            // if no dimension size is specified return size 1x1
            dimSize[0] = 1;
            dimSize[1] = 1;
            *ndim = 2;
        }

        return dimSize;
    }


    static char * createSizeStr(mwSize ndim, const mwSize *dims)
    /*
     * Create size string
     *
     * Return pointer to string with size numbers        
     * Space for string will be allocated and needs to be freed with mxFree
     * when not needed anymore.
     *
     * ndim        : number of dimensions
     * dims        : size in each dimension
     */{
    #ifdef MX_COMPAT_32
            char *sizeStr = (char *)mxMalloc((ndim*11)*sizeof(char));  // max number of characters for mwSize equals 10 + space
            int pos = 0;
            for(mwSize n=0; n+1<ndim; n++)
            {
                pos += sprintf(sizeStr+pos, "%d ", dims[n]);           
            }
            sprintf(sizeStr+pos, "%d", dims[ndim-1]);   // last size without a space
    #else
            char *sizeStr = (char *)mxMalloc((ndim*16)*sizeof(char));  // max number of characters for mwSize equals 15 + space
            int pos = 0;
            for(mwSize n=0; n+1<ndim; n++)
            {
                pos += sprintf(sizeStr+pos, "%" PR_SIZET "u ", dims[n]);           
            }
            sprintf(sizeStr+pos, "%" PR_SIZET "u", dims[ndim-1]);   // last size without a space
    #endif
            return sizeStr;
    }
    
    
    
    Utils()
    {
        if(instanceCount)
        {
            mexErrMsgIdAndTxt(MSGID_DEVEL, "Utils can be instatiated only once!");
        }
            
        Utils::instanceCount++;
    };
    
    ~Utils()
    {
        /*if(b64Decoder)
        {
            delete b64Decoder;
        }*/
    }
    
    void decode64(istream& istream_in, ostream& ostream_in)
    {
        /*if(!b64Decoder)
        {
            b64Decoder = new base64::decoder();
        }
        b64Decoder->decode(istream_in, ostream_in);
        */
    }
    
private:
    static unsigned instanceCount;
//    base64::decoder *b64Decoder;
};

unsigned Utils::instanceCount = 0;

Utils gUtils;
