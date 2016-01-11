
from transform import *






if __name__ == '__main__':
    
    #code = """
    #if (a != b) {
    #    a = a@2 + b;
    #} else x = y;
    #"""
    
    templates = {}
    gen_values = {}
    env = Environment()
    
    env.declare(Object('', 'CFG', PredefinedConstant(CfgVectType())))
    env.declare(Object('', 'ctxt', PredefinedConstant(Natural())))
    env.declare(Object('', 'hello', Input(PerCtxt(BreakpointInfo()))))
    env.declare(Object('', 'breakpoints', Output(PerCtxt(BreakpointInfo())), initspec='banana'))
    env.declare(Object('', 'a', Variable(Data())))
    env.set_implicit_ctxt('ctxt')
    
    code = """
    {others => 0}
    """
    
    #load_code([('<internal>:%s' % i, s) for i, s in enumerate(code.split('\n'))],
    #    templates, gen_values, env, 'In test code: ')
    
    vhdl, c = transform_expression(
        code,
        '<internal>',
        BreakpointInfo(),
        gen_values,
        env,
        'In test code: ',
        False,
        True)
    
    
    #import pprint
    #print(parsed.pp_ast())
    #print(str(parsed))
    
