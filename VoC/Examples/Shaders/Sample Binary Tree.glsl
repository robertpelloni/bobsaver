#version 420

//binary format for depth first enumeration of a tree

//each column of 64 bits is a "key"
//every 8 bits is treated as a level in the tree
//each bit set corrosponds to the branch at that level of the key

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D renderbuffer;

out vec4 glFragColor;

vec3 color_gradient(float x);
float contour(float x, float r);
float edge(vec2 p, vec2 a, vec2 b);
float line(vec2 p, vec2 a, vec2 b, float r);

void main( void ) 
{
    vec2 fc         = gl_FragCoord.xy;
    vec2 uv         = fc/resolution.xy;

    
    int ix            = int(fc.x)/8;
    int ioffset        = mouse.x > .5 ? int((mouse.x*mouse.x-.25) * 4096. + max(mouse.y*mouse.y-.1, 0.)*pow(8., 8.)) : int(time*mouse.y*32768.);

    
    float x            = 0.; 
    float y            = 0.; 
    
    float byte        = 0.;
    float bit        = 0.;
    float power        = 0.;    
    float sum        = 0.;
    float key        = 0.;
    
    
    if(true) //depth first
    {
        y         = floor(fc.y) * 64./resolution.y;    
        byte        = ceil(y * .125); 
        bit        = floor(mod(y, 8.));
        power        = pow(8., byte);    
        
        
        bool glslsb_h4x = ceil(y * .125) == 1. && mouse.x < .5;        
        ioffset        = glslsb_h4x ? int(time * 256.) : ioffset;

        x         = float(ix+ioffset);

        
        
        
        sum        = mod(x, power)/power * 8. - bit;
        key        = floor(mod(sum, byte * 8.)) == 0. ? 1. : 0.;            
    }
    
    vec4 result         = vec4(.0, .0, .0, 1.);    
    
    vec3 color        = vec3(.0, .0, .0);        

    bool left_panel        = floor(fc.x*.125) < floor(resolution.x*.0625);
    if(left_panel)
    {    
        x         = float(ix);
        y         = floor(fc.y) * 64./resolution.y;
        float grid    = mod(fc.x + 8., 8.) < 1. || mod(fc.y, resolution.y/64.) < 1. ? 0. : 1.;        
        color        = color_gradient((byte-.15)/8.5)*1.5;    
        
        color.xyz    += byte <= 2. ? .125 * key : 0.;
        result.xyz    += grid > 0. ? grid * key * color : (.175 - vec3(1., 1., 1.) * -grid);

        result.w    = key+.1;
    }
    else
    {
        float edge[8];

        for(int i = 7; i >= 0; i--)
        {
            edge[i] = -100.;
            for(float j = 7.; j >= 0.; j--)            
            {
                vec2 sample_uv    = vec2(1./resolution.x, 0.);
                sample_uv.y    = (float(i+1)-(j+1.)*.125+.0625)*.125;
                
                vec4 sample     = texture2D(renderbuffer, sample_uv);
                
                if(sample.w > 0.5)
                {
                    edge[i] = 8.-j;    
                    
                    break;
                }
            }
        }

        
        vec2 position_prior    = vec2(0.75, 1.);
        vec2 position_next    = vec2(0.75, .875);
        float line_width     = .5;
        float edge_key        = 0.;
        float tree_plot        = 0.;
        bool valid_key        = true;
        for(int i = 0; i < 8; i++)
        {        
            edge_key     = edge[7-i];
            if(edge_key > 0.)
            {
                float key_offset = clamp(edge_key-4., -4., 4.) - .25;
                
                if(mouse.x < .25)
                {
                    position_next.x    = .75  + key_offset * .055;                                            
                }
                else
                {
                    position_next.x    += key_offset * (1./(1.5-uv.y)/94.);                            
                }
            }
            else
            {
                valid_key = false;
            }
            
            tree_plot     = max(tree_plot, line(uv, position_prior, position_next, line_width) * byte);
            position_prior    = position_next;
            position_next.y    -= .125;
        }    
        
        if(valid_key)
        {    
            color        = color_gradient((byte-.15)/8.5)*1.5;    
            color.xyz    += byte <= 2. ? (2.-byte)*.85 : 0.;
            vec4 prior     = texture2D(renderbuffer, uv);            
            result.xyz    = max(tree_plot * color * .6103, max(prior.xyz-.005, prior.xyz*.95 - tree_plot));
        }
        else
        {
            result         *= 0.;    
        }
    }

    result            = clamp(result, 0., 1.);

    glFragColor         = result;
}//sphinx

vec3 color_gradient(float x)
{
    //"vec3 spectral_zucconi(float x)"
    //http://glslsandbox.com/e#42733.1
    const vec3 cs     = vec3(3.54541723, 2.86670055, 2.29421995);
    const vec3 xs     = vec3(0.69548916, 0.49416934, 0.28269708);
    const vec3 ys     = vec3(0.02320775, 0.15936245, 0.53520021);

    vec3 y         = vec3(1.0) - pow(cs * (x - xs), vec3(2., 2., 2.));
    y         = clamp(y - ys, 0.0, 1.9);
    return y;
}

float contour(float x, float r)
{
    return 1.-clamp(x*(dot(vec2(r),resolution)), 0., 1.);
}

float edge(vec2 p, vec2 a, vec2 b)
{
    vec2 q    = b - a;    
    float u = dot(p - a, q)/dot(q, q);
    u     = clamp(u, 0., 1.);

    return distance(p, mix(a, b, u));
}

float line(vec2 p, vec2 a, vec2 b, float r)
{
    vec2 q    = b - a;    
    float u = dot(p - a, q)/dot(q, q);
    u     = clamp(u, 0., 1.);

    return contour(edge(p, a, b), r);
}
