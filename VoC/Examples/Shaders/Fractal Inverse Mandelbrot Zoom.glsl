#version 420

// original https://www.shadertoy.com/view/3l3BWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int MAXITER = 4000;
float MAXBound = 2000.0;
vec3 col;
float ret;

int pointcheck (vec2 uv)
{
   float denom= uv.x*uv.x+uv.y*uv.y;
   vec2 npt,pt;
   uv.x=uv.x/denom;
   uv.y=uv.y/denom;
   pt.x=0.0;
   pt.y=0.0;
for (int i=1; i<MAXITER; i++)
    {
       if (length(pt) > MAXBound) return i;
       npt.x = (pt.x*pt.x-pt.y*pt.y)+uv.x;
       npt.y = (2.0*pt.x*pt.y)+uv.y;
        pt.x=npt.x;
        pt.y=npt.y;
    }    
return 0;
}

void main(void)
{
    float time=time;
    
    vec2 target = vec2(2.91521,0.41271);
    // -1.2550,.3836  NICE  
    // 2.7588, 0.5149 
    // 2.91521,0.41271
    // to use other points from original Mandelbrot,
    // use denom = x^2+y^2, x=x/denom, y=y/demon

    
    vec2 uv = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;    

        
    float zoo = 0.75 + 0.38*cos(.07*time);
    float coa = cos( 0.15*(1.0-zoo)*time );
    float sia = sin( 0.15*(1.0-zoo)*time );
    zoo = pow( zoo,8.0);
    vec2 xy = vec2( uv.x*coa-uv.y*sia, uv.x*sia+uv.y*coa);
        

    vec2 c=vec2(target)+xy*zoo;

    // check mandelbrot
    float ret = float(pointcheck(c));

    // pixel color
    col += 0.5 + 0.5*cos( 3.0 + ret*0.15 + vec3(0.0,0.6,1.0));

    // Output to screen
    glFragColor = vec4(col,1.0);

}
