
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
    env.declare(Object('', 'a', Register(Data()), initspec='3'))
    env.declare(Object('', 'b', Variable(Natural()), initspec='25'))
    env.declare(Object('', 'x', Variable(Boolean()), initspec='true'))
    env.set_implicit_ctxt('ctxt')
    
    code = """
    if (x) {
        b = 1;
        a[0, 16] = a + b;
    } else {
        <?vhdl @lvalue a <= (others => '0'); ?>
        <?c @lvalue a = 0; ?>
    }
    """
    
    transform_code([('<internal>:%s' % i, s) for i, s in enumerate(code.split('\n'))],
        templates, gen_values, env, 'In test code: ', True)
    
    #vhdl, c = transform_code(
    #    code,
    #    {},
    #    BreakpointInfo(),
    #    gen_values,
    #    env,
    #    'In test code: ',
    #    False,
    #    True)
    
    
    #import pprint
    #print(parsed.pp_ast())
    #print(str(parsed))
    
