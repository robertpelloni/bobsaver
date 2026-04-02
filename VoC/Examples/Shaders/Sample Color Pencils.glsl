#version 420

// original https://www.shadertoy.com/view/7ddGzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: bitless
// Title: Colour Pencils

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  http://www.iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

#define s(sm,p,i,j) smoothstep (p+sm,p-sm,abs(i)+j)

vec3 p(vec2 uv, vec2 l, vec2 sh, float sm, out float a)
{
        float ys = fract(sin(dot(floor(uv),vec2(12.9898,78.233)))*43758.5453123); //random y-shift and color for cell
        vec3 c = .6 + .6 * cos(6.3*(ys) + vec3(0.,23.,21.)); //base color HUE
        ys += (sin(time*ys*2.+ys*3.)-1.)*.25; //y-shift moving 
        l.x += sh.x;
        ys += sh.y;
        
        a = (smoothstep(1.,.5,abs(l.x)+(l.y-ys))*.6 + s(sm,.5,l.x,l.y-ys)*.4)*s(sm,.5,l.x,0.); //alpha mask
        vec3 f = l.y < ys ? c*.6 :vec3(0.); //base color
        f = mix (f,vec3(.9,.9,.6), s(sm,.5,l.x,abs(l.y-ys))); //yellow nib
        f = mix (f,c, s(sm,.2,l.x,abs(l.y-ys-.3))); //color nib
        f *= (1.-abs(l.x)) * (smoothstep(sm,-sm,l.x)+1.5)/2.; //light & shadow 
        return f; 
}

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec2 r = resolution.xy
        ,uv = ((g+g-r)/r.y+vec2(0.,-time*0.3))*vec2(4, 1)*vec2(.75)
        ,l = fract(uv); //cell local coords 
    float  sm = 3./r.y //smoothing factor
            ,a; //alpha
    
    l.x -= .5;
    l.y *= 4.;
    
    vec3 f = p(uv+vec2(0.,1.),l,vec2(0.,4.5),sm,a); //top neighbor
    f = mix (f,p(uv+vec2(9.,0.),l,vec2(-.5,2.),sm,a),a); //left neighbor
    f = mix(f,p(uv+vec2(8.,0.),l,vec2(.5,2.),sm,a),a); //right neighbor
    f = mix(f,p(uv,l,vec2(0.,.5),sm,a),a); 
    glFragColor = vec4(f,1.);
}
