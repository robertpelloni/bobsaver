#version 420

// original https://www.shadertoy.com/view/4ltXDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// based on Umbrellar by candycat

float circle(vec2 center, float radius, vec2 coord )
{
    return length(center-coord) - radius;
}

float square(vec2 center,float radius, vec2 coord)
{
    vec2 d = coord-center;
    return max(abs(d.x),abs(d.y))-radius;
}

float rect(vec2 center, float half_width, float half_height,vec2 coord)
{
    vec2 p = coord-center;
    return max(abs(p.x)-half_width,abs(p.y)-half_height);
}

float perc_in_range_clamped(float edge0, float edge1, float value)
{
    return clamp((value-edge0)/(edge1-edge0),0.0,1.0);
}

float trapetzoid(vec2 center, float upper_half_width, float lower_half_width, float half_height, vec2 coord)
{
    vec2 p = coord-center;
    float width = mix(upper_half_width,lower_half_width,perc_in_range_clamped(-half_height,half_height,p.y));
    return rect(center,width,half_height,coord);
}

float line(vec2 p0, vec2 p1, float width, vec2 coord)
{
    vec2 dir0 = p1 - p0;
    vec2 dir1 = coord - p0;
    float h = clamp(dot(dir0, dir1)/dot(dir0, dir0), 0.0, 1.0);
    return (length(dir1 - dir0 * h) - width * 0.5);
}

float opSU( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float opU( const float a, const float b )
{
    return min(a, b);
}

float opS( const float a, const float b)
{
    return max(a, -b);
}

float opI( const float a, const float b )
{
    return max(a, b);
}

float f_width(float f)
{
    return pow((pow(dFdx(f),2.0) + pow(dFdy(f),2.0)),0.5);
}

vec4 render(float d, vec3 color, float stroke)
{
    float fw = f_width(d);
    float anti = fw * 1.0;
    float fw_stroke = fw*stroke;
    vec4 strokeLayer = vec4(vec3(0.05), 1.0-smoothstep(-anti, anti, d - fw_stroke));
    vec4 colorLayer = vec4(color, 1.0-smoothstep(-anti, anti, d));

    if (stroke < 0.000001) {
        return colorLayer;
    }
    //return mix(vec4(0.0),vec4(1.0),smoothstep(0.0,0.04,d));
    return  vec4(mix(strokeLayer.rgb, colorLayer.rgb, colorLayer.a), strokeLayer.a);

}

float ballon(vec2 center, float radius, vec2 coord,float pearness)
{
    float enlongation = pearness*radius;
    float l = line(center,center -vec2(0.0,enlongation+radius),0.75*radius,coord);
    float c = circle(center,radius,coord);
    float t = trapetzoid(center-vec2(0.0,enlongation+1.44*radius),0.1*radius,0.02*radius,0.1*radius,coord);
    return opSU(t,opSU(l,c,0.5*radius),0.03*radius);
}

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/min(resolution.y,resolution.x);

    float size = min(resolution.x, resolution.y);
    float pixSize = 1.0 / size;
    vec2 uv = gl_FragCoord.xy / resolution.x;
    float stroke = 1.5;
    vec2 center = vec2(0.0,0.0);
    
    vec3 white = vec3(1.0);
    vec3 black = vec3(0.0);
    vec3 blue  = vec3(0.4,0.5,0.6);
    vec3 red   = vec3(0.8,0.3,0.3);
    vec3 green = vec3(0.4,0.7,0.4);
       vec3 yellow = vec3(0.8,0.8,0.3);
       vec3 orange = vec3(0.8,0.4,0.15);
    vec3 colors[5];
    colors[0]=blue;
    colors[1]=red;
    colors[2]=green;
    colors[3]=yellow;
    colors[4]=orange;

    vec4 layer0 = vec4(0.0);
    vec4 layer1 = vec4(0.0);
    vec3 bcol = blue*1.5*(1.0-0.30*length(p));
    
        
    glFragColor = vec4(bcol, 1.0);  
    for(float i = 0.0; i < 20.0;i++)
    {
        float r = mod(i * 101.0,31.0);//silly random
        float theta = time + r;
        center = vec2(0.2*i-1.7,sin(theta)*2.3*sign(cos(theta))); //d/dx sin = cos, dir(sin) = sign(cos) 
        center += vec2(sin(center.y*2.0)/10.0,0.0);
        
        vec4 b = render(ballon(center,0.4+0.1*sin(theta),p,sin(r)*0.2),
                        colors[int(mod(mod(i*101.0,31.0),5.0))],1.5); //rcalc r, can't store because of const
        glFragColor = mix(glFragColor, b, b.a);
    }
    
   
    
    glFragColor.rgb = pow(glFragColor.rgb, vec3(1.0/2.2));
}
