#version 420

// original https://www.shadertoy.com/view/lltfWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define maxStep 512
#define epsilon 0.0001

vec2 rot2D(vec2 v, float a)
{
    float c = cos(a);
    float s = sin(a);
    
    return mat2(c,-s,s,c)*v;
}

float smoothAbs(float x)
{
    
    return sqrt(x*x + 0.01);
    
}

///// Fonctions de distance ///

float forme( vec3 p, vec3 o, float r )
{
     vec3 u = p - o;
    
    
    u.y += -1.8*smoothAbs(u.x)*((23.+smoothAbs(u.x))/100.);
    
    u.z *= 1.5;
    
    
    
    float os = sin(2.*time + 0.9*p.y);
    r = r+ os*os*os*os*.1;
    
    
    return length( u) - r;
}

float sol(vec3 p, vec3 o)
{
 return p.y - o.y;   
}

float sphere(vec3 p, float r)
{
 return length(p)-r;   
}

///////

float map(vec3 p) // ici on met en place la scène    
{
    
    
    
    vec2 pRot = rot2D(p.xz, p.y/4. + time);
    
    
    
    float d1 = forme(vec3(pRot.x, p.y, pRot.y), vec3(0.), 1.);
    
    
    
    float d2 = sol(p, vec3(0.,-1.3,0.));
    
    
    
    
    return min(d1,d2);
}

/// fonction de raymarching ( on recherche une intersection )

vec3 intersection(vec3 ro, vec3 rd)
{
    float t = 0.;
    
    float d = 0.;
    
    for(int i = 0; i <= maxStep; i++)
    {
        
        d = map(ro + t*rd);
        
        if (d < epsilon) /// si on est trop près, on s'arrête
        {
            break;
        }
        
        t += d;
        
          
        
    }

    return ro + t*rd; /// on renvoie l endroit ( approché ) d une intersection
}

vec3 normale(vec3 p )
{
    vec3 u = vec3(0.);
    vec3 a = vec3(1.,0.,0.);
    vec3 b = vec3(0.,1.,0.);
    vec3 c = vec3(0.,0.,1.);
    u.x += map(p + epsilon*a) - map(p - epsilon*a);
    u.y += map(p + epsilon*b) - map(p - epsilon*b); ///on calcule la normale du point considéré
    u.z += map(p + epsilon*c) - map(p - epsilon*c);
    
    
    
    return normalize(u);
}

 //definition des lumieres

vec3 l1Pos = vec3(2.,2.,3.);
vec3 l1Int = vec3(0.8,0.,0.);

/// ici on définit une fonction d ombre

float smoothShadow(vec3 p, vec3 lPos, vec3 lInt)
{
    vec3 rd = normalize(lPos - p);
    
    
    vec3 pImp = intersection(p + rd , rd); //on envoie un rayon jusqu'à la source de lumière et on regarde si il y arrive
    
    float d = length(lPos - p);
    
    if(map(pImp) > 10.*epsilon)
       {
           return 0.;
       }
     return 0.8/d; 
    
}

///on définit un matériau pour la scène
vec3 BaseShading(vec3 p, vec3 ro)
{
    vec3 n = normale(p);
    
    vec3 col = vec3(0.);
     
    
    
    
    if (map(p) < epsilon)
    {
        vec3 l1 = normalize(l1Pos - p); /// vecteur unitaire dirigé vers la source de lumière 1
        vec3 rop = normalize(ro-p); /// vecteur unitaire dirigé vers la caméra
        
        float d = dot(l1, n) + 1.;
        
        d = (d+1.)/2.;
        
        col += max(0., d-.5) * l1Int; //diffuse simple
        
        ///spec
        
        vec3 reflet = (l1 - 2.*dot(l1,n)*n); //calcul du rayon réfléchi
        
        float a =  max(0.,dot(-reflet,rop));
        //a = a*a;
        a = a*a;
        
        col += a*.5;
        
        
                    
        col += (vec3(0.8,1.,1.) - dot(rop,n)) * .8; //bords blancs
        
        
        
        
        col -= smoothShadow(p, l1Pos, l1Int);
        
        
        
        
        return col;
        
    }
    
    
    return vec3(0.);
}

    

void main(void)
{
    
    vec2 uv = gl_FragCoord.xy/resolution.xy -.5;
    
    float ratio = resolution.x/resolution.y;
    
    uv.x *= ratio;

    
    vec3 ro = vec3(0.,0.,4.);
    
    vec3 rd = normalize(vec3(uv.xy, -1.));
    
    
    
    
    vec3 inter = intersection(ro, rd);
    
    
    
    
    
    vec3 col = BaseShading(inter,ro);
    
    col *= smoothstep(1.,0.3, length(uv.xy ));
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
