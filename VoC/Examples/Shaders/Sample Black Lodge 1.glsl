#version 420

// original https://www.shadertoy.com/view/NsBSWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float tri(float y){
    return abs(2.*fract(y)-1.);
}

vec4 texPiso(vec2 uv){
    vec4 col1 = vec4(0.24,0.,0.,1.);
    vec4 col2 = vec4(0.8,0.8,0.7,1.);
    return tri(uv.y*6.+tri(fract(uv.x)*3.)) > 0.5 ? col1 : col2;
}

vec4 texCort(vec2 uv, float mod){
    vec4 col1 = vec4(0.5,0.,0.,1.);
    vec4 col2 = vec4(0.8,0.8,0.7,1.);
    return vec4(vec3(tri(uv.y*(5.-mod)+tri(fract(uv.x)*3.))),1.)*col1;
}

float luma(vec3 rgb){
    vec3 y = vec3(0.2126,0.7152,0.0722);
    return dot(rgb,y);
}

///////////////////////////
float det = .001;
float maxdist = 30.;
int maxsteps = 150;

float objid;

mat2 rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c,s,-s,c);
}
vec2 hash2( vec2  p )
{
    p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
    return fract(sin(p)*43758.5453);
}

float sphere(vec3 p, float rad) 
{
    return length(p) - rad;
}

float box(vec3 p, vec3 c)
{
    p=abs(p)-c;
    return length(max(p,0.))+min(0.,max(p.z,max(p.x,p.y)));
}

float ground(vec3 p, float y) 
{
    p.y += y;
    return abs(p.y);
}

float cortinas(vec3 p, float x){
    p.x += x;
    return(abs(p.x));
}

float sdPlane( vec3 p, vec3 n, float h )
{
  // n must be normalized
  return dot(p,n) + h;
}

// FUNCION DE ESTIMACION DE DISTANCIA

float de(vec3 p) 
{
    vec3 pos = p;

    float piso = ground(pos, 2.);
    
    //float cortina1 = cortinas(p, 3.);
    float depthPliegues = 5.;
    float cortina1 = sdPlane(p, vec3(1.,0.,0.), 3.-depthPliegues*luma(texCort(p.zz*0.75,0.).rgb));
    float cortina2 = sdPlane(p, vec3(-1.,0.,0.), 3.+depthPliegues*luma(texCort(p.zz*0.5,1.).rgb));
    //float cortina2 = cortinas(p, -3.);
    
    //float d = min(piso, cortina1);
    //cortina1 = max(cortina1, -p.y-1.25);//offset
    float d = min(min(piso, cortina1),cortina2);

    // en lugar de establecer el color de los objetos aquí, vamos a pasar un id
    // que va a tomar la función shade para calcular el color allí
    // esta es una forma de obtener un id que sería 1 para la esfera, 2 para el piso
        
    objid = step(piso, d) + step(cortina1, d) * 2. + step(cortina2, d) * 3.;

    return d*.5;
}

// FUNCION NORMAL

vec3 normal(vec3 p) 
{   
    vec2 d = vec2(0., det);
    
    return normalize(vec3(de(p + d.yxx), de(p + d.xyx), de(p + d.xxy)) - de(p));
}

// FUNCION SHADOW
// calcula la sombra, generando un efecto de suavizado de los bordes
// a medida que se aleja del objeto

float shadow(vec3 p, vec3 ldir) {
    float td=.001,sh=1.,d=det;
    for (int i=0; i<100; i++) {
        p+=ldir*d;
        d=de(p);
        td+=d;
        sh=min(sh,10.*d/td);
        //el valor cambia la definicion del borde de la sombra
        //sh=min(sh,50.*d/td);
        if (sh<.001) break;
    }
    return clamp(sh,0.,1.);
}

// FUNCION SHADE

vec3 shade(vec3 p, vec3 dir) {

    // aquí definimos el color del objeto según la variable objcolor seteada en la funcion
    // de distancia. La guardamos en col antes de llamar a la funcion normal

    vec3 col;
    //if (objid==2. || objid==3.) col=vec3(.5,.0,.1);
    if (objid==2.) col=texCort(p.zz*0.5, 0.).rgb;
    if (objid==3.) col=texCort(p.zz*0.5, 1.).rgb;    
    //if (objid==1.) col=vec3(0.,.5,.6);
    if (objid==1.) col=texPiso(p.xz*0.5).rgb;
    
    //vec3 lightdir = normalize(vec3(1.5, 2., -1.)); 
    //vec3 lightdir = normalize(vec3(0., mouse*resolution.xy.y, -10. + (time * 0.) * 5.));
    //vec3 lightdir = normalize(vec3(mouse*resolution.xy.x/resolution.x*10.-5., mouse*resolution.xy.y/resolution.y*500.-250., 10.));
    //vec3 lightdir = normalize(vec3(0, .5, mouse*resolution.xy.x/resolution.x*10.-5.));
    //hace falta que la luz se desplace también?
     vec3 lightdir = normalize(vec3(0., .5, 5.));
    
    vec3 n = normal(p);

    // llamamos a la función sombra que nos dará un valor entre 0 y 1
    // segun el nivel de oclusión de la luminosidad
    // luego multiplicamos la luz difusa y la especular por este valor
    float sh = shadow(p, lightdir);    
    
    float diff = max(0., dot(lightdir, n)) * sh; // multiplicamos por sombra;
    
    vec3 refl = reflect(dir, n);
    
    float spec = pow(max(0., dot(lightdir, refl)), 20.) * sh; // multiplicamos por sombra;
    
    float amb = .1;
    
    //estrobo
    //if(mod(hash2(vec2(time*0.001)).x,2.)<0.01)amb=tan(time);
    
    return col*(amb*4. + diff*5.) + spec * .7;
    
}

// FUNCION DE RAYMARCHING

vec3 march(vec3 from, vec3 dir) 
{

    float d, td=0.;
    vec3 p, col;

    for (int i=0; i<maxsteps; i++) 
    {
        p = from + td * dir;

        d = de(p);

        if (d < det || td > maxdist) break;

        td += d;
    }

    if (d < det)
    {
        p -= det * dir;
        col = shade(p, dir);
    } else {
        // si no golpeo con ningun objeto, llevamos la distancia a la máxima
        // que se definió, o sea al fondo de la escena
        // esto sirve para el correcto cálculo de la niebla
        td = maxdist;
    }
    // efecto niebla
    // mix entre el color obtenido y 
    //col = mix(vec3(.7),col, exp(-.004*td*td));
    col = mix(vec3(abs(sin(time*0.01))*.5+.3),col, exp(-.004*td*td));
    return col;    
}
///////////////////////////

void main(void)
{
     vec2 uv = gl_FragCoord.xy/resolution.xy - .5; 

    uv.x *= resolution.x / resolution.y; 
    
    // oscilamos la posicion de la cámara en z
    //vec3 from = vec3(0., 0., -10. + sin(time * .5) * 5.);
    //vec3 from = vec3(0., 0., -10. + (time * .25) * 5.);
    vec3 from = vec3(0., 0., -10. + (time * .25) * 5.);
    //vec3 dir = normalize(vec3(uv, 1.));
    vec3 dir = normalize(vec3(uv, 0.75));
    //una forma simple de rotar la cámara
    //es rotando en los mismos ejes tanto from como dir
    from.xz *= rot(time*.0);
    dir.xz *= rot(time*.0);

    vec3 col = march(from, dir);

    glFragColor = vec4(col, 1.);
}
