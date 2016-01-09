

        #if literal.type == 'lit_true':
            #self['value'] = 1
            #self['type'] = 'boolean'
            
        #elif literal.type == 'lit_false':
            #self['value'] = 0
            #self['type'] = 'boolean'
            
        #elif literal.type == 'lit_nat':
            #self['value'] = int(literal.value, 0)
            #self['type'] = 'natural'
            
        #elif literal.type == 'lit_bit':
            #self['value'] = int(literal.value[1], 0)
            #self['type'] = 'bit'
            
        #elif literal.type == 'lit_vec':
            #v = literal.value.split('"')
            #t = v[0].lower()
            #bits_per_char = 4 if 'x' in t else 1
            #if v[1] == '':
                #self['value'] = 0
            #else:
                #self['value'] = int(v[1], 2**bits_per_char)
            #size = bits_per_char * len(v[1])
            #if 'u' in t:
                #self['type'] = 'unsigned%d' % size
            #else:
                #self['type'] = 'bitvec%d' % size
            
        #else:
            #raise Exception('Unknown literal type %s.' % literal.type)
        
