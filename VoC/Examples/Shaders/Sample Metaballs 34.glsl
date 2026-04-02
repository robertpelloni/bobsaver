#version 420

// original https://www.shadertoy.com/view/ssVXWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float CLOSE_ENOUGH = 0.001;
const float RENDER_DISTANCE = 30.0;
const vec3 COLOR = vec3(227., 186., 129.)/255.;
const vec3 BG_COLOR = vec3(.05,.7,.025);
const vec3 SHADOW_COLOR = vec3(.1,.9,.8);

const vec2 v1params = vec2(1.0,  .5);
const vec2 v2params = vec2(2.0, 1.3);
const vec2 v3params = vec2(1.5,  .6);
const vec2 v4params = vec2(0.5,  .3);
const vec2 v5params = vec2(0.75,1.0);

//  HSB fns from Iñigo Quiles @ https://www.shadertoy.com/view/MsS3Wc
vec3 rgb2hsb( in vec3 c ) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsb2rgb( in vec3 c ) {
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0), 6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

struct sphere
{
    vec3 c;
    float r;
};

float sphereDist(vec3 p, sphere s)
{
    return distance(p, s.c) - s.r;
}

//from iq : https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opSmoothUnion( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float sdf(vec3 p)
{
    float returnVal = .0;
    
    
    //vec3 rep = vec3(4.0, 2., 1.);
    vec3 pr = p;//mod(p, rep) - .5 * rep; 
        
    sphere s1 = sphere(vec3(sin(time*v1params.x), sin(time*v1params.y), 1.), .3);
    sphere s2 = sphere(vec3(sin(time*v2params.x), sin(time*v2params.y), 1.), .4);
    sphere s3 = sphere(vec3(sin(time*v3params.x), sin(time*v3params.y), 1.), .45);
    sphere s4 = sphere(vec3(sin(time*v4params.x), sin(time*v4params.y), 1.), .2);
    sphere s5 = sphere(vec3(sin(time*v5params.x), sin(time*v5params.y), 1.), .2);
    
    float smoothness = .2;
    returnVal = opSmoothUnion(sphereDist(pr, s1), sphereDist(pr,s2), smoothness);
    returnVal = opSmoothUnion(returnVal, sphereDist(pr, s3), smoothness);
    returnVal = opSmoothUnion(returnVal, sphereDist(pr, s4), smoothness);
    returnVal = opSmoothUnion(returnVal, sphereDist(pr, s5), smoothness);
    
    return returnVal; 
}

//from iq https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 p )
{
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*sdf( p + k.xyy*CLOSE_ENOUGH ) + 
                      k.yyx*sdf( p + k.yyx*CLOSE_ENOUGH ) + 
                      k.yxy*sdf( p + k.yxy*CLOSE_ENOUGH ) + 
                      k.xxx*sdf( p + k.xxx*CLOSE_ENOUGH ) );
}

// Inverse Distance Weighting - for color interpolation
vec3 calculateIDW(vec2 p) {
    vec3 v1 = vec3(sin(time*v1params.x), sin(time*v1params.y), 1.);
    vec3 v2 = vec3(sin(time*v2params.x), sin(time*v2params.y), 1.);
    vec3 v3 = vec3(sin(time*v3params.x), sin(time*v3params.y), 1.);
    vec3 v4 = vec3(sin(time*v4params.x), sin(time*v4params.y), 1.);
    vec3 v5 = vec3(sin(time*v5params.x), sin(time*v5params.y), 1.);
       
    // Shepard's method
    // https://en.wikipedia.org/wiki/Inverse_distance_weighting
    float powerParam = 5.;
    float w1 = 1./pow(distance(vec3(p.x, p.y, 1.), v1), powerParam);
    float w2 = 1./pow(distance(vec3(p.x, p.y, 1.), v2), powerParam);
    float w3 = 1./pow(distance(vec3(p.x, p.y, 1.), v3), powerParam);
    float w4 = 1./pow(distance(vec3(p.x, p.y, 1.), v4), powerParam);
    float w5 = 1./pow(distance(vec3(p.x, p.y, 1.), v5), powerParam);
    vec3 u1 = vec3(.4,  1., 1.);
    vec3 u2 = vec3(.7,  1., 1.);
    vec3 u3 = vec3(.8,  1., 1.);
    vec3 u4 = vec3(.89,  1., 1.);
    vec3 u5 = vec3(.5,  1., 1.);
    
    vec3 u = (w1*u1 + w2*u2 + w3*u3 + w4*u4 + w5*u5)/(w1+w2+w3+w4+w5);
    return u;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv    = gl_FragCoord.xy / resolution.xy - vec2(0.5);
         uv.x *= resolution.x / resolution.y;
    vec3 cameraPos = vec3(.0, .0, .0);//vec3(.0,sin(time)*.5,.0);// + time);
    
    // Time varying pixel color
    vec3 ro = vec3(cameraPos.x + uv.x, cameraPos.y + uv.y, cameraPos.z);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1.0));
    vec3 col = hsb2rgb(BG_COLOR);
    //col = calculateIDW(uv.xy); 
    float dist = .0;
    
    float pWidth = .005;
    if (false) {
        /*distance(uv.xy*2., vec2(sin(time*v1params.x), sin(time*v1params.y))) < pWidth ||
        distance(uv.xy*2., vec2(sin(time*v2params.x), sin(time*v2params.y))) < pWidth ||
        distance(uv.xy*2., vec2(sin(time*v3params.x), sin(time*v3params.y))) < pWidth ||
        distance(uv.xy*2., vec2(sin(time*v4params.x), sin(time*v4params.y))) < pWidth ||
        distance(uv.xy*2., vec2(sin(time*v5params.x), sin(time*v5params.y))) < pWidth) {
        glFragColor = vec4(1.,1.,1., 1.0);*/
    }
    else{    
        vec3 lightDir = normalize(vec3(sin(time*0.125), sin(time*0.25), -1.0));

        while(dist < RENDER_DISTANCE)
        {
            float d = sdf(ro + rd * dist);
            if(d < CLOSE_ENOUGH)
            {

                vec3 hit = ro + rd * dist;
                col = calculateIDW(hit.xy);//BLUE; 
                col *= mix(hsb2rgb(SHADOW_COLOR), col, max(dot(calcNormal(hit), lightDir), .0));
                col = hsb2rgb(col);
                break;
            }
            dist += d;
        }

        // Output to screen
        glFragColor = vec4(col, 1.0);
        }
}
