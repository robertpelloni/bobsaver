#version 420

// original https://www.shadertoy.com/view/3dySDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define timeScale 1.

float N11(float n)
{
    vec2 v1 = vec2(fract(n*129.3484),fract(n*10.2347+1.4948));
    vec2 v2 = vec2(49.256,n);
    return fract(dot(v1,v2));
}

vec2 N12(float n)
{
    vec2 v1 = vec2(fract(n*33.24102+1.2847),fract(n*4.70234556-2.5856));
    vec2 v2 = vec2(39.3823+n,n*3.1938+1.4028);
    return vec2(fract(dot(v1,v2)),N11(dot(v1,v2)));
}

vec2 N22(vec2 p)
{
    return vec2(N11(4.238+p.y+p.x*0.6274),N11(3.4148*p.y-8.29*p.x+1.39558));
}

float perlin(vec2 p,float scale, float seed)
{
    vec2 pS = p*scale;
    
    float X1 = floor(p.x*scale);
    float X2 = X1+1.;
    float Y1 = floor(p.y*scale);
    float Y2 = Y1+1.;
    
    vec2 v11 = vec2(X1,Y1);
    
    vec2 gpUnfaded = pS - v11;
    float xCub = pow(gpUnfaded.x,3.);
    float yCub = pow(gpUnfaded.y,3.);
    vec2 gp = vec2((6.*gpUnfaded.x*gpUnfaded.x-15.*gpUnfaded.x+10.)*xCub,
              (6.*gpUnfaded.y*gpUnfaded.y-15.*gpUnfaded.y+10.)*yCub);
    
    vec2 v12 = vec2(X1,Y2);
    vec2 v21 = vec2(X2,Y1);
    vec2 v22 = vec2(X2,Y2);
    
    vec2 d11 = gp-v11;
    vec2 d12 = gp-v12;
    vec2 d21 = gp-v21;
    vec2 d22 = gp-v22;
    
    float fact = 1.394+seed;
    vec2 g11 = (N22(v11*fact)-.5)*2.;
    vec2 g12 = (N22(v12*fact)-.5)*2.;
    vec2 g21 = (N22(v21*fact)-.5)*2.;
    vec2 g22 = (N22(v22*fact)-.5)*2.;
    
    vec2 contribY1 = mix(g11,g21,gp.x);
    vec2 contribY2 = mix(g12,g22,gp.x);
    
    vec2 contrib = mix(contribY1,contribY2,gp.y);

    float value= dot(d11,contrib)+dot(d12,contrib)-dot(d21,contrib)-dot(d22,contrib);
    
    return mix(0.,1.,value);
}

vec3 starColor(vec2 p, float id, float radius)
{
    //center of the star
    vec2 center = N12(id)-.5;
    //random color
    vec3 color = vec3(N11(id),N11(id*7.2819),N11(id/2.));
    vec2 vec = center-p;
    float dist = (length(vec));
       float angle = abs(sqrt(abs(vec.x*vec.y)))*5.;
    float star = smoothstep(radius*.3,radius*.25,dist);
    float halo = smoothstep(radius*1.2,.0,dist)*(.7+abs(sin(time*(20.+center.x*40.)))*.3);
    float scint = smoothstep(1.,.0,angle)*halo*(.7+abs(sin(time*(10.+center.x*20.)))*.3);
    return star*vec3(sqrt(color))+(scint+halo)*color;
}

vec3 layerColor(vec2 uv, float layerIndex,float scale)
{
    uv = uv*scale;
    //random seed for this layer
    float seed = 2.309387+layerIndex*1.283374;
    //subdivision into squares
    vec2 gv = (fract(uv*10.)*2.)-1.;
    //id of the square
    float id= seed*1.4983*floor(uv.y*10.)+5.39283*floor(uv.x*10.);
    //random radius for the star
    float radius = mix(.1,.5,N11(id*3.82918));
       //is the start in this square visible?
    float visible = smoothstep(.95,.96,N11(id*19.10982));
    //value of the star to draw
    vec3 starColor = starColor(gv,id,radius);
    
    
    return starColor*visible;
}

vec3 nebula(vec2 uv,float scale, float seed)
{
    uv = uv*scale;
    vec3 color = 0.5 + 0.5*cos(time*.4*timeScale-length(uv)+vec3(0,2,4));
    
     //value of the nebula
    float valPerlin = perlin(uv,scale,seed)+.6*perlin(uv,5.*scale,seed)+.3*perlin(uv,7.*scale,seed);
    vec3 colNebul = smoothstep(-1.,1.,valPerlin)*color*.12*(.2+.2*length(uv));  
    
    return colNebul;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy/resolution.xy*2.)-1.;
    uv.x *= resolution.x/resolution.y;
    
    vec3 col = vec3(0.);
    
    
    float time = time*timeScale;
    // Number of layers
    float nbLayers = 20.;
    float step = .5;
    float width = nbLayers * step;
    
    for(float i = 1. ; i < nbLayers; i++)
    {
        float posI = mod(width-(time+i),width+0.5);
        float scale =posI;
        float visible = clamp(2.-abs(posI - 2.), 0.,1.);
        vec3 nebulVal = nebula(uv,scale,i)*.7;
        col += visible*(layerColor(uv,i,scale)+nebulVal);
    }
                                                                   
    // Output to screen
    glFragColor = vec4(col,1.0);
}
