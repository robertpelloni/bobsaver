#version 420

// original https://www.shadertoy.com/view/wt23z1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
 * This just traces through a field of cubes that make a box, plus two
 * extra cubes plus lightsources.
 */

// #define ENABLE_SHADOWS /* Compute intensive */
#define ENABLE_NORMAL_MAPPING
#define ENABLE_SPECULAR

#define MAT_REFLECTANCE 3.0
#define BRIGHTNESS 10.0
#define ID_NONE 0.0
#define ID_TUNNEL 1.0
#define ID_LIGHT1 2.0
#define ID_LIGHT2 4.0
#define LIGHT1_COLOR vec3(.8,.05,.667)
#define LIGHT2_COLOR vec3(.05,.05,2.0)

/*
    Creates and orientates ray origin and direction vectors based on a
    camera position and direction, with direction and position encoded as
    the camera's basis coordinates.
*/
void camera(in vec2 uv, in vec3 cp, in vec3 cd, in float f, out vec3 ro, out vec3 rd)
{
    ro = cp;
    rd = normalize((cp + cd*f + cross(cd, vec3(0,1,0))*uv.x + vec3(0,1,0)*uv.y)-ro);
}

/**
 * Minimum of two 2D vectors.
 */
vec2 min2( in vec2 a, in vec2 b )
{
    if (a.x < b.x) return a;
    else return b;
}

/**
 * Minimum of two 3D vectors.
 */
vec3 min4( in vec3 a, in vec3 b )
{
    if (a.x < b.x) return a;
    else return b;
}

/**
 * Minimum of two 4D vectors.
 */
vec4 min4( in vec4 a, in vec4 b )
{
    if (a.x < b.x) return a;
    else return b;
}

/**
 * Takes the minimum of two intersections.
 */
void minInt(in float distA,  in vec3 normA,  in vec2 uvA,
            in float distB,  in vec3 normB,  in vec2 uvB,
            out float distM, out vec3 normM, out vec2 uvM)
{
    if ( distA < distB ) { distM = distA; normM = normA; uvM = uvA; }
    else                 { distM = distB; normM = normB; uvM = uvB; }
}

/**
 * That random function off of SF.
 */
float rand( in vec2 co )
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

/**
 * 3D version.
 */
float rand3( in vec3 co )
{
    return fract(sin(dot(co ,vec3(12.9898,78.233,-53.1234))) * 43758.5453);
}

/**
 * Sorta the usual FBM, but without using a noise texture and adding
 * high frequency noise at the end.
 */
float fbm( in vec2 x )
{
    float r = 0.0;
    /*
    float r = 0.0;//texture(iChannel0, x     ).x*.5;
    r += texture(iChannel0, x*2.0 ).x*.25;
    r += texture(iChannel0, x*4.0 ).x*.125;
    r += texture(iChannel0, x*8.0 ).x*.0625;
    r += rand(x)*.0325;
    */
    return r;
}
    

/**
 * Reference function for light positions.
 */
vec3 lightpos1() { return vec3(sin(time*.5)*3., cos(time), 2.+sin(time)); }
vec3 lightpos2() { return vec3(sin(time)*3.0, -cos(time*.5)*.5, 0); }

/**
 * A kinda sorta smoothsquare function.
 */
float smoothSquare(in float x) { return smoothstep(.3, .7, pow(sin(x),2.)); }

/**
 * IQ Really nailed this one.
 */
mat4 translate( float x, float y, float z )
{
    return mat4( 1.0, 0.0, 0.0, 0.0,
                 0.0, 1.0, 0.0, 0.0,
                 0.0, 0.0, 1.0, 0.0,
                 x,   y,   z,   1.0 );
}

/**
 * IQ's sphere intersection.
 */
vec2 iSphere( in vec3 ro, in vec3 rd, in vec3 ce, float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h < 0.0 ) return vec2(99999.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

/**
 * IQ's Box intersection.
 */
float iBox( in vec3 row, in vec3 rdw, in mat4 txx, in mat4 txi, in vec3 rad, out vec3 oN, out vec2 oU ) 
{                 
    // convert from world to box space
    vec3 rd = (txx*vec4(rdw,0.0)).xyz;
    vec3 ro = (txx*vec4(row,1.0)).xyz;

    // ray-box intersection in box space
    vec3 m = 1.0/rd;
    vec3 s = vec3((rd.x<0.0)?1.0:-1.0,
                  (rd.y<0.0)?1.0:-1.0,
                  (rd.z<0.0)?1.0:-1.0);
    vec3 t1 = m*(-ro + s*rad);
    vec3 t2 = m*(-ro - s*rad);

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    
    if( tN>tF || tF<0.0) return 99999.0;

    // compute normal (in world space), face and UV
    if( t1.x>t1.y && t1.x>t1.z ) { oN=txi[0].xyz*s.x; oU=ro.yz+rd.yz*t1.x; }
    else if( t1.y>t1.z   )       { oN=txi[1].xyz*s.y; oU=ro.zx+rd.zx*t1.y; }
    else                         { oN=txi[2].xyz*s.z; oU=ro.xy+rd.xy*t1.z; }

    return tN; // maybe min(tN,tF)?
}

/**
 * A simplified version.
 */
#ifdef ENABLE_SHADOWS
float iBoxSimple( in vec3 row, in vec3 rdw, in mat4 txx, in vec3 rad ) 
{                 
    vec3 rd = (txx*vec4(rdw,0.0)).xyz;
    vec3 ro = (txx*vec4(row,1.0)).xyz;

    vec3 m = 1.0/rd;
    vec3 s = vec3((rd.x<0.0)?1.0:-1.0,
                  (rd.y<0.0)?1.0:-1.0,
                  (rd.z<0.0)?1.0:-1.0);
    vec3 t1 = m*(-ro + s*rad);
    vec3 t2 = m*(-ro - s*rad);

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    
    if( tN>tF || tF<0.0) return 99999.0;

    return tN;
}
#endif // ENABLE_SHADOWS

/**
 * Takes a ray, walks it forward, and see if it intersects
 * any columns near it.
 */
void tunnel( in vec3 ro, in vec3 rd, out float dist, out vec3 n, out vec2 uv )
{
    dist = 9999999.0; // nearest intersection distance, normal, and UV.
    n = vec3(0,1,0);
    uv = vec2(0);
    
    float intersect = 0.0; // Did we hit something?
    
    vec3 p = ro; // Copy of the ray origin.
    
    // March the ray forward.
    for(float i = 0.0; i < 9.0; ++i)
    {
        for(int x = -1; x < 2; ++x) // Left and right neighbors.
        for(int z = -1; z < 2; ++z) // Front and back neighbors.
        {
            
            
            vec3 off = vec3(x,0,z); // Create an offset vector.

            
            vec3 g = floor(p); // Floor the ray position.

            // Get the columns' height.
            float h_b = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.xz)    );
            float h_t = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.xz-1.0));
            float h_l = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.yz)    );
            float h_r = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.yz-1.0));
            float h_f = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.xy)    );
            float h_d = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.xy-1.0)); // derriere for back, since b is taken for "bottom".
            
            // Create the required translation matrices.
            mat4 t_b = translate(off.x-g.x-.5,  3.0+h_b, off.z-g.z-.5); 
            mat4 t_t = translate(off.x-g.x-.5, -3.0-h_t, off.z-g.z-.5); 
            mat4 t_l = translate(-4.0-h_l, off.x-g.y-.5, off.z-g.z-.5); 
            mat4 t_r = translate( 4.0+h_r, off.x-g.y-.5, off.z-g.z-.5); 
            mat4 t_f = translate(off.x-g.x-.5, off.z-g.y-.5, -4.0-h_f); 
            mat4 t_d = translate(off.x-g.x-.5, off.z-g.y-.5,  4.0+h_d);
            
            // And their inverses.
            mat4 t_bi = inverse(t_b), t_ti = inverse(t_t), t_li = inverse(t_l);
            mat4 t_ri = inverse(t_r), t_fi = inverse(t_f), t_di = inverse(t_d);
            
            vec3 n_b, n_t, n_l, n_r, n_f, n_d;          // Places to store surface normals.
            vec2 uv_b, uv_t, uv_l, uv_r, uv_f, uv_d; // And more places to store UVs.

            // Finally we can check some intersections.
            float dist_b = iBox(p, rd, t_b, t_bi, vec3(.5), n_b, uv_b) + i;
            float dist_t = iBox(p, rd, t_t, t_ti, vec3(.5), n_t, uv_t) + i;
            float dist_l = iBox(p, rd, t_l, t_li, vec3(.5), n_l, uv_l) + i;
            float dist_r = iBox(p, rd, t_r, t_ri, vec3(.5), n_r, uv_r) + i;
            float dist_f = iBox(p, rd, t_f, t_fi, vec3(.5), n_f, uv_f) + i;
            float dist_d = iBox(p, rd, t_d, t_di, vec3(.5), n_d, uv_d) + i;
            
            // Find the nearest intersection.
            minInt( dist, n, uv, dist_t, n_t, uv_t, dist, n, uv );
            minInt( dist, n, uv, dist_b, n_b, uv_b, dist, n, uv );
            minInt( dist, n, uv, dist_l, n_l, uv_l, dist, n, uv );
            minInt( dist, n, uv, dist_r, n_r, uv_r, dist, n, uv );
            minInt( dist, n, uv, dist_f, n_f, uv_f, dist, n, uv );
            minInt( dist, n, uv, dist_d, n_d, uv_d, dist, n, uv );
        }
        
        // All boxes have a grid size of 1, and ||rd|| = 1.
        // This allows us to use our marching step index as the distance
        // traveled from origin.
        p += rd;
    }
    
    // Now it's time to get the two feature cubes in the middle.
    
    vec3 n_f1, n_f2; // Surface normals.
    vec2 uv_f1, uv_f2; // Texcoords.
    
    // Translation matrices.
    mat4 t_f1 = translate(-.6,-.6,-.6); mat4 t_f1i = inverse(t_f1);
    mat4 t_f2 = translate( .6, .6, .6); mat4 t_f2i = inverse(t_f2);
    
    // Check for intersection.
    float dist_f1 = iBox(ro, rd, t_f1, t_f1i, vec3(.5), n_f1, uv_f1);
    float dist_f2 = iBox(ro, rd, t_f2, t_f2i, vec3(.5), n_f2, uv_f2);
    
    // Factor them into the equation.
    minInt( dist, n, uv, dist_f1, n_f1, uv_f1, dist, n, uv );
    minInt( dist, n, uv, dist_f2, n_f2, uv_f2, dist, n, uv );
    
    // Perturb the surface normal.
    #ifdef ENABLE_NORMAL_MAPPING
    p = ro+dist*rd;
    vec2 texCoord = uv+rand3(floor(p)); 
    vec3 diff = vec3(fbm(texCoord), fbm(texCoord+12348.3), 0);
    diff = 2.0*diff - 1.0;
    diff *= .125;
    vec3 an = abs(n);
    if( an.x > .5 )      n = normalize(n+diff.zxy*sign(n.x));
    else if( an.y > .5 ) n = normalize(n+diff.xzy*sign(n.y));
    else                 n = normalize(n+diff.xyz*sign(n.z));
    #endif // ENABLE_NORMAL_MAPPING
}

/**
 * Traces a ray through the field. This trace function includes
 * two spheres for the light soruces.
 */
void trace( in vec3 ro, in vec3 rd, out float id, out float dist, out vec3 n, out vec2 uv)
{
    tunnel(ro, rd, dist, n, uv);
    float si1 = iSphere(ro, rd, lightpos1(), .05).x;
    float si2 = iSphere(ro, rd, lightpos2(), .05).x;
       
    vec2 minElement = vec2(9999999.0, ID_NONE);
    minElement = min2(minElement, vec2(dist, ID_TUNNEL));
    minElement = min2(minElement, vec2(si1,  ID_LIGHT1));
    minElement = min2(minElement, vec2(si2,  ID_LIGHT2));
       dist = minElement.x;
    id = minElement.y;
            
}

/**
 * Marches a ray forward through a simplified geometry field, since
 * we don't need the UV or normal vector of where the shadow ray
 * collides.
 */
#ifdef ENABLE_SHADOWS
void tunnelShadow( in vec3 ro, in vec3 rd, out float dist )
{
    dist = 9999999.0;    
       int face;
    float intersect = 0.0;
    vec3 p = ro;
    
    for(float i = 0.0; i < 9.0; ++i)
    {
        for(int x = -1; x < 2; ++x)
        for(int z = -1; z < 2; ++z)
        {
            vec3 off = vec3(x,0,z);
            vec3 g = floor(p);

            float h_b = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.xz)    );
            float h_t = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.xz-1.0));
            float h_l = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.yz)    );
            float h_r = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.yz-1.0));
            float h_f = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.xy)    );
            float h_d = .5*smoothSquare(.25*time + 3.14*rand(off.xz-g.xy-1.0));
            
            mat4 t_b = translate(off.x-g.x-.5,  3.0+h_b, off.z-g.z-.5); 
            mat4 t_t = translate(off.x-g.x-.5, -3.0-h_t, off.z-g.z-.5); 
            mat4 t_l = translate(-4.0-h_l, off.x-g.y-.5, off.z-g.z-.5); 
            mat4 t_r = translate( 4.0+h_r, off.x-g.y-.5, off.z-g.z-.5); 
            mat4 t_f = translate(off.x-g.x-.5, off.z-g.y-.5, -4.0-h_f); 
            mat4 t_d = translate(off.x-g.x-.5, off.z-g.y-.5,  4.0+h_d);

            float dist_b = iBoxSimple(p, rd, t_b, vec3(.5)) + i;
            float dist_t = iBoxSimple(p, rd, t_t, vec3(.5)) + i;
            float dist_l = iBoxSimple(p, rd, t_l, vec3(.5)) + i;
            float dist_r = iBoxSimple(p, rd, t_r, vec3(.5)) + i;
            float dist_f = iBoxSimple(p, rd, t_f, vec3(.5)) + i;
            float dist_d = iBoxSimple(p, rd, t_d, vec3(.5)) + i;
            
            dist = min(dist, dist_b);
            dist = min(dist, dist_t);
            dist = min(dist, dist_l);
            dist = min(dist, dist_r);
            dist = min(dist, dist_f);
            dist = min(dist, dist_d);
        }
        p += rd;
    }
    mat4 t_f1 = translate(-.6,-.6,-.6);
    mat4 t_f2 = translate( .6, .6, .6);
    
    float dist_f1 = iBoxSimple(ro, rd, t_f1, vec3(.5));
    float dist_f2 = iBoxSimple(ro, rd, t_f2, vec3(.5));
    
    dist = min(dist, dist_f1);
    dist = min(dist, dist_f2);
}
#endif // ENABLE_SHADOWS

/**
 * Traces a shadow ray through the distance field.
 */
#ifdef ENABLE_SHADOWS
void traceShadow( in vec3 ro, in vec3 rd, out float dist)
{
    tunnelShadow(ro, rd, dist);
}
#endif // ENABLE_SHADOWS

/*
    Oren-Nayar reflectance modeling. I use this everywhere. Just looks good.
*/
float orenNayar( in vec3 n, in vec3 v, in vec3 ldir )
{
    float r2 = pow(MAT_REFLECTANCE, 2.0);
    float a = 1.0 - 0.5*(r2/(r2+0.57));
    float b = 0.45*(r2/(r2+0.09));

    float nl = dot(n, ldir);
    float nv = dot(n, v);

    float ga = dot(v-n*nv,n-n*nl);

    return max(0.0,nl) * (a + b*max(0.0,ga) * sqrt((1.0-nv*nv)*(1.0-nl*nl)) / max(nl, nv));
}

/**
 * Models a point light.
 */
vec3 pointLight( in vec3 p, in vec3 n, in vec3 lp, in vec3 rd, in vec3 texel, in vec3 lc )
{
    
    vec3 ld = lp-p;                                 // Direction of light.
    float dist = length(ld);                         // Distance to the light.
    ld = normalize(ld);                             // Normalize for correct trig.
    float base = orenNayar(n, rd, ld)*BRIGHTNESS;     // Base lighting coefficient.
    float falloff = clamp(1.0/(dist*dist),0.0,1.0); // Quadratic coefficient.
    
    // Specular.
    #ifdef ENABLE_SPECULAR
    vec3 reflection = normalize(reflect(rd,n));
    float specular = clamp(pow(clamp(dot(ld, reflection),0.0,1.0),25.0),0.0,1.0);
    #else
    float specular = 0.0;
    #endif // ENABLE_SPECULAR
    
    // Optionally do shadows.
    #ifdef ENABLE_SHADOWS
    float shadowDist;
    traceShadow(p+ld*.01, ld, shadowDist);
    float shadow = smoothstep(dist*.99, dist*1.01,shadowDist);
    #else
    float shadow = 1.0;
    #endif // ENABLE_SHADOWS
    
    return lc*specular*shadow + base*falloff*shadow*lc*texel + lc*.0125;
}

/**
 * Lights the entire scene by tracing both point lights.
 */
vec3 lightScene( in vec3 p, in vec3 n, in vec3 rd, in vec3 texel )
{
    
    return clamp( pointLight(p, n, lightpos1(), rd, texel, LIGHT1_COLOR) +
                    pointLight(p, n, lightpos2(), rd, texel, LIGHT2_COLOR),
                    vec3(0),vec3(1) );
}

/**
 * Takes it a step further by coloring based on object ID.
 */
vec3 shade( in vec3 p, in vec3 n, in vec3 rd, in float dist, in float id )
{
    if(id == ID_NONE) return vec3(0);
    else if(id == ID_TUNNEL) return vec3( lightScene(p+rd*dist, n, rd, vec3(1)) );
    else if(id == ID_LIGHT1) return LIGHT1_COLOR*BRIGHTNESS*2.0;
    else if(id == ID_LIGHT2) return LIGHT2_COLOR*BRIGHTNESS*2.0;
    else return vec3(0);
}

/**
 * Some quick tonemapping and vignetting.
 */
vec4 postProcess( in vec3 c, in vec2 uv )
{
    float vig = 1.0-dot(uv,uv)*.6;
    c = pow(clamp(c, 0., 1.), vec3(.4545));
    return vec4(c*vig,1);
}

/**
 * Entrypoint.
 */
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - 0.5;
    uv.x *= resolution.x/resolution.y; //fix aspect ratio
    
    // Set up the camera.
    
    // Position.
    vec3 cp =  vec3(3.0*cos(time*.5), sin(time*.25), 3.0*sin(time*.25));
    
    // Direction.
    vec3 cd = normalize(vec3(-cos(time*.5), .5*cos(time*.25), -sin(time*.25)));
    
    // Places to store results.
    vec3 p, d;
    
    // Create the view ray.
    camera(uv, cp, cd, .667, p, d);
    
    // Do the traces.
    float id; float dist; vec3 n; vec2 texCoord;
    trace(p, d, id, dist, n, texCoord);
    
    // Shade the point.
    vec3 c = shade(p, n, d, dist, id);
    
    
    
    // Based on the results of that trace, we shade accordingly.
    glFragColor = postProcess(c, uv);
}
