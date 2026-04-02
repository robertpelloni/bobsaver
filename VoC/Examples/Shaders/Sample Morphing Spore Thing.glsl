#version 420

// original https://www.shadertoy.com/view/lldGz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    "MorphingSporeThing" by wjbgrafx
    
    Based on "Playing with Symmetries - Torus" by PauloFalcao
    
    http://glslsandbox.com/e#29755.0
    
*/
//==============================================================================

// From "Raymarching Primitives" - // Created by inigo quilez - iq/2013
// https://www.shadertoy.com/view/Xds3zN

float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

//------------------------------------------------------------------------------
//Util Start

float PI=3.14159265;

vec3 sim(vec3 p,float s)
{
   vec3 ret=p;
   ret=p+s/2.0;
   ret=fract(ret/s)*s-s/2.0;
   return ret;
}

// Rotation around z-axis when vec2 p.xy;
// Rotation around y-axis when vec2 p.xz;
// Rotation around x-axis when vec2 p.yz.
vec2 rot(vec2 p,float r)
{
   vec2 ret;
   ret.x=p.x*cos(r)-p.y*sin(r);
   ret.y=p.x*sin(r)+p.y*cos(r);
   return ret;
}

// When vec2 p.xy, rotational symmetry about z-axis;
// when vec2 p.xz, rotational symmetry about y-axis
// when vec2 p.yz, rotational symmetry about x-axis
vec2 rotsim(vec2 p,float s)
{
   vec2 ret=p;
   ret=rot(p,-PI/(s*2.0));
   ret=rot(p,floor(atan(ret.x,ret.y)/PI*s)*(PI/s));
   return ret;
}

//Util End
//------------------------------------------------------------------------------

//Scene Start
//------------------------------------------------------------------------------

vec2 obj0Def( in vec3 p )
{
    return vec2( sdEllipsoid( p, vec3( 0.1 ) ), 0.0 );    
}
vec2 obj1Def( in vec3 p )
{
    return vec2( sdBox( p, vec3( 1.0, 0.02, 0.02 ) ), 1.0 );    
}
vec2 obj2Def( in vec3 p )
{
    return vec2( sdBox( p, vec3( 0.02, 1.25, 0.02 ) ), 2.0 );    
}

//------------------------------------------------------------------------------

vec3 obj0_c(in vec3 p)
{
    return vec3( abs( sin( time * 0.03 ) ), 
                 abs( sin( time * 0.05 ) ),
                 abs( sin( time * 0.07 ) ) );
}
vec3 obj1_c(in vec3 p)
{
    return vec3( abs( sin( time * 0.07 ) ), 
                 abs( sin( time * 0.03 ) ),
                 abs( sin( time * 0.05 ) ) );
}
vec3 obj2_c(in vec3 p)
{
    return vec3( abs( sin( time * 0.05 ) ), 
                 abs( sin( time * 0.07 ) ),
                 abs( sin( time * 0.03 ) ) );
}
//------------------------------------------------------------------------------

vec2 map(in vec3 p) // orange
{    
    // Rotate space around the z-axis.
    //-------------------------------------------- 
    // x-axis is now up-down, y-axis is right-left
    p.xy = rot( p.xy, PI * 0.5 );
    //-------------------------------------------- 

    // Animation
    //---------------------------------------
    // Animate object rotating around x-axis:
    p.yz = rot( p.yz, time * 0.23 );

    // Animate object rotating around y-axis:
    p.xz = rot( p.xz, time * 0.17 );

    // Animate object rotating around z-axis:
    p.xy = rot( p.xy, time * 0.13 );
    //---------------------------------------

    // Domain repetitions
    // ---------------------------------------------------

    // Copy sphere in the xy-plane via symmetry around the z-axis.
    p.xy = rotsim( p.xy, 8.0 + 6.0 * sin( time * 0.11 ) );
    // Offset sphere along the y-axis by a small amount.
    p.y -= 0.35;

    // Copy sphere in yz plane via symmetry around x-axis.
    // numCopies = 6.0
    //p.yz = rotsim( p.yz, 8.0 );    
    p.yz = rotsim( p.yz, 8.0 + 6.0 * sin( time * 0.05 ) );    
    // Offset sphere along z-axis to separate the copies wider apart.
    p.z -= 2.0;    
    
    // Copy sphere in the xz-plane via symmetry around the y-axis.
    //p.xz = rotsim( p.xz, 8.0 );
    p.xz = rotsim( p.xz, 8.0 + 6.0 * sin( time * 0.07 ) );
    // Offset sphere along the z-axis to separate copies.
    p.z -= 3.0;

    // Adding this provides a background for the object.
    p = sim( p, 6.0 );

    // Copy sphere in the xy-plane via symmetry around the z-axis.
    //p.xy = rotsim( p.xy, 3.0 );
    p.xy = rotsim( p.xy, 8.0 + 6.0 * sin( time * 0.09 ) );
    // Offset sphere along the y-axis by a small amount.
    p.y -= 0.55;

    // Copy sphere in the xy-plane via symmetry around the z-axis.
    p.xy = rotsim( p.xy, 8.0 + 6.0 * sin( time * 0.03 ) );
    // Offset sphere along the y-axis by a small amount.
    p.y -= 0.35;

    // ---------------------------------------------------

    // Objects
    //----------------------------------
    
    // spheres    
    vec2 obj0 = obj0Def( p );
    
    // vertical box connectors in xz-plane
    vec2 obj1 = obj1Def( p );
    
    // horizontal box connectors in xy-plane
    vec2 obj2 = obj2Def( p );
    //----------------------------------
    
    // Distance comparisons to find closest object
    //--------------------------------------------
    vec2 closest = obj0.s < obj1.s ? obj0 : obj1;
    closest = closest.s < obj2.s ? closest : obj2;
    
    return closest;    
}

//Scene End
//------------------------------------------------------------------------------

void main(void)
{
    // Note that original code does not perform aspect ratio adjustment here,
    // but below in the "vec3 scrnCoord =" equation.
    // vec2 vPos=-1.0+2.0*gl_FragCoord.xy/scrnRes.xy;
    
    // wjb modified to include aspect ratio adjustment here.
    // Adjust aspect ratio, normalize coords, center origin in xy-plane.    
    // xRange = -1.7777778 to 1.775926, yRange = -1.0 to 0.9981482 at 1920x1080
    vec2 vPos = ( -resolution.xy + 2.0 * gl_FragCoord.xy ) / resolution.y;

    
    //----------------
    //Camera animation
    vec3 vuv=vec3(0,1,0);//Change camere up vector here
    vec3 vrp=vec3(0,0,0); //Change camere view here
    
    // camera rotate around y-axis in xz plane
    //vec3 prp=vec3(cos(time * 0.5),0.1,sin(time* 0.5))*8.0; //camera pos
    //vec3 prp=vec3(cos(time * 0.37),-sin( time * 0.41 ),sin(time* 0.43))*12.0; 
    // camera rotate around x-axis in yz plane
    //vec3 prp=vec3(0.1,cos(time * 0.5),sin(time* 0.5))*8.0; //camera pos
    // camera rotate around z-axis in xy plane
    //vec3 prp=vec3(cos(time * 0.5),sin(time* 0.5),0.1)*8.0; //camera pos
    // Still camera from x units out of screen
    vec3 prp=vec3(0.0,0.0,-10.0); //For viewing individual components from front
    //-----------------
    
    float vpd=1.5;  // fov
    
    //Camera setup
    vec3 vpn=normalize(vrp-prp);
    vec3 u=normalize(cross(vuv,vpn));
    vec3 v=cross(vpn,u);
    
    // Original code does aspect ratio adjustment here.
    //vec3 scrCoord=prp+vpn*vpd+vPos.x*u*scrnRes.x/scrnRes.y+vPos.y*v;
    
    // wjb modified, since asp rat is done in vPos equation above.
    vec3 scrCoord=prp+vpn*vpd+vPos.x*u+vPos.y*v;
    
    vec3 scp=normalize(scrCoord-prp);
    
    //Raymarching
    const vec3 e=vec3(0.1,0,0);
    const float maxd=60.0; //Max depth
    
    vec2 s=vec2(0.1,0.0);
    vec3 c,p=vec3(0.0),n;
    
    float f=1.0;
    for(int i=0;i<256;i++)
    {
        if (abs(s.x)<.001||f>maxd) break;
        f+=s.x;
        p=prp+scp*f;
        //s=inObj(p);
        s=map(p);
    }
    
    if (f<maxd)
    {
        // Determine color of object
        //--------------------------
        if (s.y==0.0)    
              c = obj0_c( p );
        else if ( s.y == 1.0 )
            c = obj1_c( p );
        else
            c = obj2_c( p );
            
        //--------------------------
        
        //tetrahedron normal
        const float n_er=0.01;
        float v1=map(vec3(p.x+n_er,p.y-n_er,p.z-n_er)).x;
        float v2=map(vec3(p.x-n_er,p.y-n_er,p.z+n_er)).x;
        float v3=map(vec3(p.x-n_er,p.y+n_er,p.z-n_er)).x;
        float v4=map(vec3(p.x+n_er,p.y+n_er,p.z+n_er)).x;
        n=normalize(vec3(v4+v1-v3-v2,v3+v4-v1-v2,v2+v4-v3-v1));
        
        float b=dot(n,normalize(prp-p));
        //simple phong LightPosition=CameraPosition
        glFragColor=vec4((b*c+pow(b,8.0))*(1.0-f*.01),1.0);
    }
    else glFragColor=vec4(0,0,0.1,1); //background color
}

