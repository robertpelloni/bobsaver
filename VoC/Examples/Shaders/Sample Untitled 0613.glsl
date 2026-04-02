#version 420

// original https://www.shadertoy.com/view/3tcBDN

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float FARAWAY=1e30;
const float EPSILON=1e-6;

// Structure de la caméra
struct Camera {
    vec3 Obs;    // Position de l'observateur
    vec3 View;   // Vecteur unitaire pointant sur la cible
    vec3 Horiz;  // Vecteur unitaire de la direction horizontale
    vec3 Up;     // Vecteur unitaire de la direction verticale
    float H;     // Hauteur de l'écran (px)
    float W;     // Largeur de l'écran (px)
    float z;     // Décalage de l'écran
};

// Structure du ray
struct Ray {
    vec3 Origin;
    vec3 Dir;
};

// Structure d'une sphère
struct Sphere {
   vec3 Center;
   float R;
};

// Initialisation de la caméra (Obs -> position de l'observateur; Target -> cible le point central & aperture -> angle d'ouverture)
Camera camera(in vec3 Obs, in vec3 Target, in float aperture) {
   Camera C;
   C.Obs = Obs;
   C.View = normalize(Target - Obs);
   C.Horiz = normalize(cross(vec3(0.1, 0.1, 0.5), C.View));
   C.Up = cross(C.View, C.Horiz);
   C.W = float(resolution.x);
   C.H = float(resolution.y);
   C.z = (C.H/2.0) / tan((aperture * 3.1415 / 180.0) / 2.0);
   return C;
}

// Fonction d'initialisation de la lumière
Ray launch(in Camera C, in vec2 XY) {
   return Ray(
      C.Obs,
      C.z*C.View+(XY.x-C.W/2.0)*C.Horiz+(XY.y-C.H/2.0)*C.Up 
   );
}

// Gère les ombres des objets
struct Material {
    vec3 Kd;       // diffuse color
    vec3 Ke;       // emissive color
    vec3 Kr;       // reflective material
    float checker; // checkerboard size
    vec3 Ks;       // specular
    float s;       // specular factor
};

// Vecteur nul
const vec3 zero3 = vec3(0.0, 0.0, 0.0);

// Créé un materiel diffus 
Material diffuse(in vec3 Kd) {
   return Material(Kd, zero3, zero3, 0.0, zero3, 0.0);
}

// Source de lumière
Material light(in vec3 Ke) {
   return Material(zero3, Ke, zero3, 0.0, zero3, 0.0);
}

// Créé une surface réfléchissante
Material mirror(in vec3 Kd, in vec3 Kr) {
   return Material(
     Kd, zero3, Kr, 0.0, vec3(1.0, 1.0, 1.0), 30.0
   );
}

// Créé une surface brillante
Material shiny(in vec3 Kd, in vec3 Ks) {
   return Material(Kd, zero3, zero3, 0.0, Ks, 30.0);
}

// Créé un damier
Material checkerboard(in vec3 Kd, in vec3 Kr, in float sz) {
   return Material(Kd, zero3, Kr, sz, zero3, 0.0);
}

// Structure d'un objet (forme + materiel)
struct Object {
   Sphere sphere;
   Material material;
};

// La scène est stockée dans un array global
Object scene[18];

// \brief Initialise la scène
void init_scene() {

   scene[0] = Object(
      Sphere(vec3(0.0, 0.0, -10000.0),9999.5),
      // mirror(vec3(0.2, 0.5, 0.2), vec3(0.5, 0.5, 0.5))
      checkerboard(vec3(0, 0, 0), vec3(0.5, 0.5, 0.5), 0.5)
   );

   //scene[1] = Object(
   //   Sphere(vec3(1.0, 0.0, 1.0),0.02),
   //   light(vec3(1.0, 1.0, 1.0))
   //);
   
   scene[1] = Object(
      Sphere(vec3(0.0, 0.0, 1.0),0.5), 
      mirror(vec3(0.5, 0.5, 0.5), vec3(1.0, 1.0, 1.0))
   );
   
   //Haut
   for(int i=0; i<5; ++i) {
     float beta = float(frames)/30.0 + float(i)*6.28/5.0;
     float s = sin(beta);
     float c = cos(beta); 

     scene[i+2] = Object(
        Sphere(vec3(0.7*s, 0.7*c, 2.0),0.1), 
        light(vec3(0.5, 0.5, 0.5))
        //mirror(vec3(1.0, 0.7, 0.7), vec3(0.3, 0.3, 0.3))
     );
   }
   
   //Bas
   for(int i=0; i<5; ++i) {
     float beta = float(frames)/30.0 + float(i)*6.28/5.0;
     float s = sin(beta);
     float c = cos(beta); 

     scene[i+7] = Object(
        Sphere(vec3(0.7*s, 0.7*c, 0.0),0.1), 
        light(vec3(0.5, 0.5, 0.5))
        //mirror(vec3(1.0, 0.7, 0.7), vec3(0.3, 0.3, 0.3))
     );
   }
   
   //Ceinture
   for(int i=0; i<5; ++i) {
     float beta = -float(frames)/60.0 + float(i)*6.28/5.0;
     float s = sin(beta);
     float c = cos(beta); 

     scene[i+13] = Object(
        Sphere(vec3(1.2*s, 1.2*c, 1.0),0.1), 
        mirror(vec3(1.0, 0.7, 0.7), vec3(0.3, 0.3, 0.3))
     );
   }
}

// Affichage d'une sphère
bool intersect_sphere(in Ray R, in Sphere S, out float t) {
   vec3 CO = R.Origin - S.Center;
   float a = dot(R.Dir, R.Dir);
   float b = 2.0*dot(R.Dir, CO);
   float c = dot(CO, CO) - S.R*S.R;
   float delta = b*b - 4.0*a*c;
   if(delta < 0.0) {
      return false;
   }
   t = (-b-sqrt(delta)) / (2.0*a);
   return true;
}

// Calcule la réflexion de lumière
Ray reflect_ray(in Ray I, in vec3 P, in vec3 N) {
   return Ray(
      P,
      -2.0*dot(N,I.Dir)*N + I.Dir
   );
}

// \brief Tests whether a Ray is in shadow
// \param[in] R a Ray that connects a point to a lightsource
// \retval true if the point is in shadow w.r.t. the lightsource
// \retval false otherwise
bool shadow(in Ray R) {
   for(int i=0; i<scene.length(); ++i) {
        float t;
        if(
          scene[i].material.Ke == vec3(0.0, 0.0, 0.0) &&
          intersect_sphere(R, scene[i].sphere, t) &&
          t > EPSILON && t < 1.0
        ) {
          return true;
        }
    }
    return false;
}

// \brief Computes the lighting
// \param[in] P the intersection point
// \param[in] N the normal to the intersected surface at P
// \param[in] material the material
// \param[in] Ray the incident Ray
// \return the computed color
vec3 lighting(
   in vec3 P, in vec3 N, in Material material, in Ray R
) {

   // If it is a lightsource, then return its color
   // (and we are done) 
   if(material.Ke != vec3(0.0, 0.0, 0.0)) {
      return material.Ke;
   }  

   vec3 result = vec3(0.0, 0.0, 0.0);

   // Compute the influence of all lightsources
   for(int i=0; i<scene.length(); ++i) {
      if(scene[i].material.Ke != vec3(0.0, 0.0, 0.0)) {
         Ray R2 = Ray(P, scene[i].sphere.Center);
         if(!shadow(R2)) {
           vec3 E = scene[i].sphere.Center - P;
  
           // Diffuse lighting
           float lamb = max(0.0, dot(E,N) / length(E));
           vec3 Kd = material.Kd;
           if(material.checker != 0.0 && 
              sin(P.x/material.checker)*
              sin(P.y/material.checker) > 0.0) {
               Kd = vec3(1.0, 1.0, 1.0) - Kd;
           }
           result += lamb * Kd * scene[i].material.Ke;

           // Specular lighting
           if(material.Ks != zero3) {
               vec3 Er = 2.0*dot(N,E)*N - E;
               vec3 View = R.Origin - P;
               float spec=max(dot(Er,View),0.0);
               spec /= sqrt(dot(Er,Er)*dot(View,View));
               spec = pow(spec, material.s);
               result += 
                  spec * material.Ks * scene[i].material.Ke;
           }
         }
      }
   }

   return result;
}

// \brief Computes the nearest intersection along a Ray
// \param[in] R the ray
// \param[out] P the intersection point
// \param[out] N the normal to the intersected surface at P
// \param[out] material the material of the intersected object
bool nearest_intersection(
   in Ray R, 
   out vec3 P, out vec3 N, out Material material
) {
   const float FARAWAY=1e30; 
   float t = FARAWAY;

   for(int i=0; i<scene.length(); ++i) {
       float cur_t;

       if( intersect_sphere(R, scene[i].sphere, cur_t) 
          && cur_t < t && cur_t > EPSILON ) {
           t = cur_t;
           P = R.Origin + t*R.Dir;
           N = normalize(P - scene[i].sphere.Center);
           material = scene[i].material;
       } 
   }
   
   return (t != FARAWAY);
}

void main(void) {

   // Yes, it is a bit stupid to call this for each pixel,
   // but well, does not cost that much...
   init_scene();

   float beta = float(frames)/400.0;
   float s = sin(beta);
   float c = cos(beta); 

   // Initialize the Camera (and make it orbit around the
   // origin)
   Camera C = camera(
       vec3(4.0*c, 4.0*s, 1.5),
       vec3(1.0, 1.0, 1.0),
       60.0       
   );

   // Lauch the primary ray that corresponds to this pixel
   Ray R = launch(C, gl_FragCoord.xy);
   
   
   glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

   vec3 P;  // Current intersected point
   vec3 N;  // Normal to the intersected object at P
   Material material; // Material of the intersected object
 
   // Compute up to 5 ray bounces
   vec3 Kr_cumul = vec3(1.0, 1.0, 1.0);
   for(int k=0; k<5; ++k) {
       if(nearest_intersection(R, P, N, material)) {
          glFragColor.rgb += Kr_cumul * lighting(P,N,material,R);
          if(material.Kr == zero3) {
              break;
          }
          Kr_cumul *= material.Kr;
          R = reflect_ray(R, P, N);
       } else {
          glFragColor.rgb += Kr_cumul * vec3(0, 0, 0);
          break;
       }
   }
}
