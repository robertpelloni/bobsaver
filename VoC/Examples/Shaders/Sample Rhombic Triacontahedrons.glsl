#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//rhombic triacontahedron
//sphinx

#define minkowski(v, m) pow(dot(pow(v, v*0.+m), v*0.+1.), 1./m)
#define TAU     (8. * atan(1.))
#define PHI     ((sqrt(5.)+1.)*.5)
#define PHI2     (PHI*PHI)
#define PHI3     (PHI*PHI*PHI)

#define VIEW_POSITION vec3(0., 0., -68.)

vec3 g_color         = vec3(0., 0., 0.);
#define SLICE        = mouse.x * resolution.x < gl_FragCoord.x;
mat2 rmat(float t)
{
    float c = cos(t);
    float s = sin(t);
    return mat2(c, s, -s, c);
}

float cube(vec3 p, vec3 s)
{
    vec3 d = abs(p) - s;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float segment(vec3 p, vec3 a, vec3 b, float r)
{

    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);

//    return min(length(pa - ba * h), min(length(p-b), length(pa))-r*6.)-r;
    //return min(length(pa - ba * h),length(p)-r*24.)-r;
    //return min(length(p-b), length(pa))-r*6.;
    return length(pa - ba * h)-r;
    //return length(p)-r*24.;
}

float dot2( in vec3 v ) { return dot(v,v); }
float udQuad( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d )
{
    vec3 ba = b - a; vec3 pa = p - a;
    vec3 cb = c - b; vec3 pb = p - b;
    vec3 dc = d - c; vec3 pc = p - c;
    vec3 ad = a - d; vec3 pd = p - d;
    vec3 nor = cross( ba, ad );

    return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(dc,nor),pc)) +
     sign(dot(cross(ad,nor),pd))<3.0)
     ?
     min( min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(dc*clamp(dot(dc,pc)/dot2(dc),0.0,1.0)-pc) ),
     dot2(ad*clamp(dot(ad,pd)/dot2(ad),0.0,1.0)-pd) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}

vec3 e_color     = vec3(0., 0., 0.);
float rtc_edges(vec3 position, float radius)
{        
        position    = abs(position);

    vec4 v         = vec4(PHI3, PHI2, PHI, 0.);
    
    float ea    = segment(position, v.xyw, v.yyy, radius);
    float eb    = segment(position, v.xyw, v.xwz, radius);
    float ec    = segment(position, v.xyw, v.zxw, radius);
    float ed    = segment(position, v.ywx, v.yyy, radius);
    float ee    = segment(position, v.ywx, v.wzx, radius);
    float ef    = segment(position, v.ywx, v.xwz, radius);
    float eg    = segment(position, v.wxy, v.yyy, radius);
    float eh    = segment(position, v.wxy, v.wzx, radius);
    float ei    = segment(position, v.wxy, v.zxw, radius);
    float edges    = min(min(min(min(min(min(min(min(ea, eb), ec), ed), ee), ef), eg), eh), ei);

    e_color     = ea == edges ? vec3(1., 0., 1.) : e_color;
    e_color     = eb == edges ? vec3(1., 1., 0.) : e_color;
    e_color     = ec == edges ? vec3(1., 1., 1.) : e_color;
    e_color     = ed == edges ? vec3(0., 1., 0.) : e_color;
    e_color     = ee == edges ? vec3(0., 1., 1.) : e_color;
    e_color     = ef == edges ? vec3(1., 0., 0.) : e_color;
    e_color     = eg == edges ? vec3(0., 0., 0.) : e_color;
    e_color     = eh == edges ? vec3(-1., -1., -1.) : e_color;
    e_color     = ei == edges ? vec3(0., 0., 1.) : e_color;
    
    return edges;
}

vec3 f_color     = vec3(0., 0., 0.);
float rtc_faces(vec3 position, float radius)
{        
    position    = abs(position);

    vec4 v         = vec4(PHI3, PHI2, PHI, 0.);
    
    float fa    = udQuad(position, v.yyy, v.xyw, v.xwz, v.ywx);
    float fb    = udQuad(position, v.yyy, v.ywx, v.wzx, v.wxy);
    float fc    = udQuad(position, v.yyy, v.wxy, v.zxw, v.xyw);
    float fd    = udQuad(position, v.xwz, v.xyw,  v.xyw, v.xwz * vec3(1., 1., -1.));
    float fe    = udQuad(position, v.wzx, v.ywx,  v.ywx, v.ywx * vec3(-1., 1., 1.));
    float ff    = udQuad(position, v.wxy, v.zxw,  v.zxw, v.zxw * vec3(-1., 1., 1.));
    float faces     = min(min(min(min(min(fa, fb), fc), fd), fe), ff);

    f_color     = fb == faces ? vec3(0., 1., 0.) : f_color;
    f_color     = fc == faces ? vec3(1., 0., 1.) : f_color;
    f_color     = fa == faces ? vec3(1., 0., 0.) : f_color;    
    f_color     = fd == faces ? vec3(1., 1., 0.) : f_color;
    f_color     = fe == faces ? vec3(0., 1., 1.) : f_color;
    f_color     = ff == faces ? vec3(0., 0., 1.) : f_color;
    
    return faces-.00625;
}

vec3 v_color     = vec3(0., 0., 0.);
float rtc_vertices(vec3 position, float radius)
{        
    position    = abs(position);

    vec4 v         = vec4(PHI3, PHI2, PHI, 0.);

    float va    = length(position-v.yyy)-radius; //center
    float vb     = length(position-v.xyw)-radius; //right
    float vc     = length(position-v.xwz)-radius; //bottom right
    float vd     = length(position-v.ywx)-radius; //bottom center
    float ve     = length(position-v.wzx)-radius; //left
    float vf     = length(position-v.wxy)-radius; //top left
    float vg     = length(position-v.zxw)-radius; //top right
    float verts    = min(min(min(min(min(min(va, vb), vc), vd), ve), vf), vg);
    
    v_color     = va == verts ? vec3(1., 0., 0.) : v_color;
    v_color     = vb == verts ? vec3(1., 0., 1.) : v_color;
    v_color     = vc == verts ? vec3(1., 1., 0.) : v_color;
    v_color     = vd == verts ? vec3(0., 1., 0.) : v_color;
    v_color     = ve == verts ? vec3(0., 1., 1.) : v_color;
    v_color     = vf == verts ? vec3(0., 0., 1.) : v_color;
    v_color     = vg == verts ? vec3(1., 1., 1.) : v_color;
    

    g_color     = v_color;
    
    
    return verts;
}

float map(vec3 position)
{
    float range     = 8192.;
    
    
    vec3 origin     = position * clamp(mouse.y + .5, .5, 1.);
//    origin.zy     *= rmat(mouse.y*TAU*4.-TAU*.5);
//    origin.xz     *= rmat(mouse.x*TAU+TAU/2.);
    origin.xz     *= rmat(time * .0625);
    origin.yz     *= rmat(time * .0625);        
    float bounds    = cube(origin, vec3(PHI3*3.));    
    float radius     = .125;

    float k     = 13.7082039325/PHI;

    origin        = mod(origin+k/2., k)-k/2.;

    //float verts     = rtc_vertices(origin, radius*2.);        
    float edges     = rtc_edges(origin, radius);    
    //float faces    = rtc_faces(origin, radius);    

    range         = edges;

    //g_color     = verts == range ? v_color : g_color;
//    g_color     = edges == range ? e_color : g_color;
    //g_color     = faces == range ? f_color : g_color;    
    g_color        = vec3(1., 1., 1.);
    range        = max(bounds, range);
    
    return range;
}

float map2(vec3 position)
{
    float range     = 8192.;
    vec3 origin     = position  * clamp(mouse.y + .5, .5, 1.);
//    origin.zy     *= rmat(mouse.y*TAU*4.-TAU*.5);
//    origin.xz     *= rmat(mouse.x*TAU+TAU/2.);
    origin.xz     *= rmat(time * .0625);
    origin.yz     *= rmat(time * .0625);    
    float bounds    = cube(origin, vec3(PHI3*2.975));    

    float radius     = .125;

    float k     = 13.7082039325/PHI;

    
    bool offset    = mouse.x*resolution.x < gl_FragCoord.x;
    if(offset)
    {
        origin    += PHI3;
        origin     = mod(origin+k/2., k)-k/2.;
    }
    else
    {
        origin    = mod(origin+k/2., k)-k/2.;    
    }
    

    float verts     = rtc_vertices(origin, radius*2.);        
    //float edges     = rtc_edges(origin, radius);    
    float faces    = rtc_faces(origin, radius);    

    range         = min(verts,faces);

    g_color     = verts == range ? v_color : g_color;
    //g_color     = edges == range ? e_color : g_color;
    g_color     = faces == range ? f_color : g_color;    

    range        = max(bounds, range)-.05;
    
    return range;
}

vec3 derive2(in vec3 position, in float range)
{
    vec2 offset     = vec2(0., range);
    vec3 normal     = vec3(0.);
    normal.x        = map2(position+offset.yxx)-map2(position-offset.yxx);
    normal.y        = map2(position+offset.xyx)-map2(position-offset.xyx);
    normal.z        = map2(position+offset.xxy)-map2(position-offset.xxy);
    return normalize(normal);
}

vec3 derive(in vec3 position, in float range)
{
    vec2 offset     = vec2(0., range);
    vec3 normal     = vec3(0.);
    normal.x        = map(position+offset.yxx)-map(position-offset.yxx);
    normal.y        = map(position+offset.xyx)-map(position-offset.xyx);
    normal.z        = map(position+offset.xxy)-map(position-offset.xxy);
    return normalize(normal);
}

float smoothmin(float a, float b, float x)
{
    return -(log(exp(x*-a)+exp(x*-b))/x);
}

float shadow(vec3 origin, vec3 direction, float mint, float maxt, float k) 
{
    float sh = 1.0;
    float t = mint;
    float h = 0.0;
    for (int i = 0; i < 32; i++) 
    {
        if (t > maxt)            
            continue;
            h     = map(origin + direction * t);
            sh     = smoothmin(sh, k * h/t, 8.0);
            t     += clamp( h, 0.01, 0.5 );        
    }
    return clamp(sh, 0., 1.);
}

float ambient_occlusion2(vec3 position, vec3 normal)
{       
    float delta     = 0.05;
    float occlusion = 0.0;
    float t     = .5;
    for (float i = 1.; i <= 12.; i++)
    {
        occlusion    += t * (i * delta - map2(position + normal * delta * i));
        t         *= .86;
    }
     
    const float k     = 4.0;
    return 1.0 - clamp(k * occlusion, 0., 1.);
}

float shadow2(vec3 origin, vec3 direction, float mint, float maxt, float k) 
{
    float sh = 1.0;
    float t = mint;
    float h = 0.0;
    for (int i = 0; i < 32; i++) 
    {
        if (t > maxt)            
            continue;
            h     = map2(origin + direction * t);
            sh     = smoothmin(sh, k * h/t, 8.0);
            t     += clamp( h, 0.01, 0.5 );        
    }
    return clamp(sh, 0., 1.);
}

float ambient_occlusion(vec3 position, vec3 normal)
{       
    float delta     = 0.125;
    float occlusion = 0.0;
    float t     = .2;
    for (float i = 1.; i <= 9.; i++)
    {
        occlusion    += t * (i * delta - map(position + normal * delta * i));
        t         *= .5;
    }
     
    const float k     = 4.0;
    return 1.0 - clamp(k * occlusion, 0., 1.);
}

void main( void ) 
{
    vec2 aspect        = resolution.xy/resolution.yy;
    
    vec2 uv         = gl_FragCoord.xy/resolution.xy;
    uv             = (uv - .5) * aspect;
    
    vec2 m            = (mouse-.5) * aspect;
    
    
    
    vec3 direction      = normalize(vec3(uv, PHI));

    vec3 origin        = VIEW_POSITION;
    vec3 position        = origin;
    
    
    
    //raytrace
    float minimum_range    = 1./max(resolution.x, resolution.y);
    float max_range        = 8192.;
    float range        = max_range;
    float total_range    = 0.;
    float steps         = 0.;
    
    vec3 background_color     = (vec3(.375, .375, .5) - uv.y) * .8625;
    vec3 material_color    = vec3( .45, .35, .12) * .85;    
    
    vec3 color         = background_color;
    
    float origional_range    = range;
    
    
////pass 0    
    origin            = VIEW_POSITION;
    position        = origin;
    
    minimum_range        = 1./max(resolution.x, resolution.y);
    max_range        = 8192.;
    range            = max_range;
    total_range        = 0.;
    steps             = 0.;
    for(int count = 1; count < 64; count++)
    {
        if(range > minimum_range && total_range < max_range)
        {
            steps++;
            
            range         = map(position);
            range        *= .85;
            minimum_range    *= 1.04;

            
            total_range    += range;

        
            position     = origin + direction * total_range;    
        }
    }
    
    origional_range    = total_range;
    
    if(steps < 63. && total_range < max_range)
    {
        vec3 surface_direction     = derive(position, .5*minimum_range);
    
        vec3 light_position     = VIEW_POSITION+vec3(-64., 32., -16.);
        vec3 light_direction    = normalize(light_position - position);
        
        float light        = max(dot(surface_direction, light_direction), 0.);
            
        vec3 reflection     = reflect(direction, surface_direction);
        float specular         = pow(clamp(dot(reflection, light_direction), 0.0, 1.0), 24.0);

        material_color         = mix(material_color, g_color, .25)*.65;
        color             = material_color + material_color * light * 1.25 + specular * .5;
        color            -= min(abs(total_range/steps*8.)*.0125, .5);
        color             += ambient_occlusion(position, surface_direction)*.125;
        color             *= .85 + .25 * shadow(position, light_direction, 0., 322., 64.);
    }
////
    
    
        
////pass 1    
    origin            = VIEW_POSITION;
    position        = origin;
    
    minimum_range        = 1./max(resolution.x, resolution.y);
    max_range        = 8192.;
    range            = max_range;
    total_range        = 0.;
    steps             = 0.;
    for(int count = 1; count < 64; count++)
    {
        if(range > minimum_range && total_range < max_range)
        {
            steps++;
            
            range         = map2(position);
            range        *= .85;
            minimum_range    *= 1.04;

            
            total_range    += range;

        
            position     = origin + direction * total_range;    
        }
    }
    
    
    if(steps < 63. && total_range < max_range)
    {
        if(origional_range >= total_range)
        {
        vec3 surface_direction     = derive2(position, .5*minimum_range);
    
        vec3 light_position     = VIEW_POSITION+vec3(-64., 32., -16.);
        vec3 light_direction    = normalize(light_position - position);
        
        float light        = max(dot(surface_direction, light_direction), 0.);
        light            = pow(light, 2.2);
        
        vec3 reflection     = reflect(direction, surface_direction);
        float specular         = pow(clamp(dot(reflection, light_direction), 0.0, 1.0), 24.0);
        float bounce         = pow(clamp(dot(reflection, normalize(surface_direction-light_direction)), 0.0, 1.0), 16.0);
        material_color         = mix(material_color, g_color, .5);
        color             += material_color + material_color * light + specular * 1.5 + bounce * .75;
        color             *= ambient_occlusion2(position, surface_direction)*.125+.825;
        color            -= min(abs(total_range/steps*32.)*.0125, .5);
        color             *= .5 + .5 * shadow2(position, light_direction, .001, 32., 8.);
        color            += abs((1.+total_range)/(1.+steps*5.))*.85;    
        }
        else 
        {
            color         = color * .75 + .5;
        }
        
    }
////
    
    
    
        
    color                 = pow(color * .5, vec3(1.6, 1.6, 1.6));
    
    glFragColor             = vec4(color, 1.);
}//sphinx
