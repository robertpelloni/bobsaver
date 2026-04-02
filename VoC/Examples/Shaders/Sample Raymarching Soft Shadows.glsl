#version 420

// original https://www.shadertoy.com/view/tlXBRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Experimenting with soft cast shadows in raymarching

//#define SHOW_OBSTRUCTION // Uncomment to show the obstruction detection only

vec3 bands(float x)
{
    // Debug function for displaying orange/blue bands for positive/negative numbers.
    float y = x*5.;
    vec3 cp = vec3(0.7,0.5,0.1);
    vec3 cm = vec3(0.1,0.5,0.7);
    if(y>0.){ if(y-floor(y)<0.5) return cp; return 0.8*cp; }
    if(y-floor(y)<0.5) return cm; return 0.8*cm;
}

vec3 colorPattern(vec3 p)
{
    //vec3 q = p/length(p);
    //vec3 col = bands(q.x) + bands(q.y) * bands(q.z);
    vec3 col = vec3(1.);
    return col;
}

float sphereSDF(vec3 pos)
{
    // Repeating pattern of spheres
    vec2 turned = vec2(pos.x+pos.y, pos.x-pos.y);
    turned = 6.0*round(turned/6.0);
    turned = vec2(turned.x+turned.y, turned.x-turned.y)/2.0;
    /*pos.x -= 3.*round(pos.x/3.);
    if(pos.y>-1.5)
        pos.y -= 3.*round(pos.y/3.);
    */
    pos.xy -= turned.xy;
    return length(pos-vec3(0.,0.,1.))-1.;
}

float planeSDF(vec3 pos)
{
    // Bottom plane
    return pos.z+0.4;
}

float floorSDF(vec3 pos)
{
    // Just a few tiles
    // Rounded box distance function by iq
    // https://www.youtube.com/watch?v=62-pRVZuS5c
    pos.xy -= 3.*round(pos.xy/3.);
    vec3 c = vec3(0., 0., -0.2);
    float rounded = 0.1;
    vec3 r = vec3(0.75, 0.75, 0.2)-rounded;
    vec3 q = abs(pos - c) - r;
    return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.) - rounded;
}

float cubeSDF(vec3 pos)
{
    // One more box..?
    vec3 c = vec3(0., -2., 0.3);
    float rounded = 0.1;
    vec3 r = vec3(0.5, 0.5, 0.3)-rounded;
    vec3 q = abs(pos - c) - r;
    //return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.) - rounded;
    return 1000.; // Nah.
}

float sceneSDF(vec3 pos)
{
    return min(min(sphereSDF(pos), cubeSDF(pos)), min(planeSDF(pos), floorSDF(pos)));
}

vec3 calculateNormal(vec3 pos)
{
    // Tetrahedral normal calculation method by iq
    vec2 e = vec2(0.002,-0.002);
    return normalize(e.xxx * sceneSDF(pos+e.xxx)
            + e.xyy * sceneSDF(pos+e.xyy)
            + e.yxy * sceneSDF(pos+e.yxy)
            + e.yyx * sceneSDF(pos+e.yyx));
}

vec3 rayDir(vec3 camFwd, float fov, vec2 uv)
{
    // In what direction to shoot?
    vec3 camUp = vec3(0.,0.,1.);
    camUp = normalize(camUp - camFwd*dot(camFwd, camUp)); // Orthonormalize
    vec3 camRight = cross(camFwd, camUp);
    return normalize(camFwd + (uv.x * camRight + uv.y * camUp)*fov);
}

float calculateObstruction(vec3 pos, vec3 lpos, float lrad)
{
    // A homemade algorithm to compute obstruction
    // Raymarch to the light source, and
    // record the largest obstruction.
    // We assume that if the ray passes through an object at depth
    // d (negative distance), then the object obstructs light
    // proportional to the relative size of d projected on the light
    // as given by Thales's theorem.
    vec3 toLight = normalize(lpos-pos);
    float distToLight = length(lpos-pos);
    float d, t=lrad*0.1;
    float obstruction=0.;
    for(int j=0; j<128; j++)
    {
        d = sceneSDF(pos + t*toLight);
        obstruction = max(0.5+(-d)*distToLight/(2.*lrad*t), obstruction);
        if(obstruction >= 1.){break;}
        // If we're stuck, advance by the characteristic 
        // size of an obstructing object
        t += max(d, lrad*t/distToLight);
        if(t >= distToLight) break;
    }
    return clamp(obstruction, 0.,1.);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv*2.-1.;
    uv.x *= resolution.x/resolution.y;
    // uv.y goes between +-1, and uv.x a bit more depending on the display format.

    // Camera ray
    vec3 ro = vec3(0., -8., 3.0);
    vec3 ri = rayDir(normalize(vec3(0.,0.,1.)-ro), 0.5, uv);

    // Normal raytracing
    float d, t=0.;
    int cause = -1;
    int j;
    for(j=0; j<128; j++)
    {
        d = sceneSDF(ro + t*ri);
        if(d<0.001){break;}
        if(d>1000.){t=1000.; break; }
        t += d; // Should be a real metric, otherwise put a *.5 or so here
    }
    vec3 pos = ro + t*ri;
    vec3 normal = calculateNormal(pos);
    
    // Compute lighting by marching again to detect obstruction
    vec3 lpos = vec3(4.*cos(time*0.5), 4.*sin(time*0.5), 4.*(1.-0.5*cos(time*2.)));
    float lightRadius = 0.6;
    float lightStrength = 20.0;//length(lpos)*length(lpos);
    float obstruction = calculateObstruction(pos, lpos, lightRadius);
    vec3 toLight = normalize(lpos-pos);
    float distToLight = length(lpos-pos);
    float diffuse = max(dot(normal, toLight), 0.)
        /(distToLight*distToLight)
        *lightStrength;
    
    float level = diffuse*(1.-obstruction);
    vec3 col = level * colorPattern(pos);
    // Tone mapping
    col = 1.-exp(-2.*col);
    
    // Output to screen
    #ifndef SHOW_OBSTRUCTION
    glFragColor.rgb = vec3(col);
    #else
    glFragColor.rgb = vec3(1.-obstruction);
    #endif
    
}
