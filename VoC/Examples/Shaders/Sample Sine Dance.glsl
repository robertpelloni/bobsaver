#version 420

// original https://www.shadertoy.com/view/4Xt3W8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    

    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 lerp(in vec3 a,in vec3 b,float f )
{
    return a*f+b*(1.-f);
}

void main(void)
{

    vec2 P=gl_FragCoord.xy;

    float t = time * 0.01;

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = ((P/resolution.xy)-vec2(0.5,0.5))*4.;

    // Time varying pixel color
    float ang=atan(uv.x,uv.y);
    float dis=sqrt(uv.x*uv.x+uv.y*uv.y);

    vec3 col1 = normalize(vec3(uv.x,uv.y,1./dis))/2.;
    vec3 col2 = vec3(uv.x,uv.y,0)/3.;

    

    vec3 col = mix(col1,col2,smoothstep(0.,1.,sin(dis+ t*33.)*.5+.5));
  //  col=col2;

    float l =1., il = 1.-l;

    int n = 20;

    int i;
    float fi; 
    t=t*40.;
    vec3 fo = vec3(t*0.97+cos(t*0.2+4.)+2.,
                   t*1.0 +sin(t*1.1+6.)+1.,
                   t*1.13+cos(t*.57+.1));
    
    vec3 f,g,ff;
    for( ;i < n  ;i++) {
        fi = float(i) / float(n),
        
        ff = vec3(11.+sin(t*0.128+4.+fi)*4., 
                  20.+sin(-t*0.5+2.+fi)*3.,
                  13.+sin(t*0.345+2.+fi)*4.),
        
        f = sin( vec3(col.y*ff.x+t*.9,
                      col.z*ff.y+t*.4,
                      col.x*ff.z+4.-t*0.2)
                     + fo ) *l ,
                     
        g = sin( vec3(col.z*1.4 - t*0.5,
                      col.x*.4 + t*0.4,
                      col.y*.40 + t*0.3)
                      *0.5+0.5
                     + fo ) *l ,
        col= col*0.999+(f+g*0.5)*0.03;

    }
    
    
    col = abs(col);
    col.x = col.x*.01+t*0.04+dis*.02;
    col.y= (col.y * col.y )+.3;
    col.z = col.z *1.5+.1;
    
    // Output to screen
    glFragColor = vec4(hsv2rgb_smooth( col),1);    
}