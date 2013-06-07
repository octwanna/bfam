#ifndef BFAM_SUBDOMAIN_H
#define BFAM_SUBDOMAIN_H

#include <bfam_base.h>
#include <bfam_mpicomm.h>
#include <bfam_critbit.h>

/**
 * base structure for all subdomains types. Any new subdomain should have this
 * as its first member with the name base, i.e.,
 * \code{.c}
 * typedef struct new_subdomain_type
 * {
 *   bfam_subdomain_t base;
 *   ...
 * }
 */
typedef struct bfam_subdomain
{
  char*           name;     /**< Name of the subdomain */
  bfam_mpicomm_t* comm;     /**< communicator for this subdomain */
  bfam_critbit0_tree_t tags; /**< critbit for tags for the subdomain */

  /* Function pointers that domain will need to call */
  void (*free)                (struct bfam_subdomain *thisSubdomain);

  /**< Write a vtk file */
  void (*vtk_write_vtu_piece) (struct bfam_subdomain *thisSubdomain,
                               FILE *file,
                               const char **scalars,
                               const char **vectors,
                               const char **components,
                               int writeBinary,
                               int writeCompressed,
                               int rank,
                               bfam_locidx_t id);
} bfam_subdomain_t;


/** initializes a subdomain
 *
 * There no new function for subdomains since these are really just a base class
 * and a concrete grid and physics type should be defined
 *
 * \param [in,out] thisSubdomain pointer to the subdomain
 * \param [in]     name Name of this subdomain
 */
void
bfam_subdomain_init(bfam_subdomain_t *subdomain,const char* name);

/** free up the memory allocated by the subdomain
 * 
 * \param [in,out] thisSubdomain subdomain to clean up
 */
void
bfam_subdomain_free(bfam_subdomain_t *thisSubdomain);

/** Add a tag to the subdomain
 *
 * \param [in,out] thisSubdomain subdomain to andd the tag to
 * \param [in]     tag           tag of the domain (\0 terminated string)
 *
 */
void
bfam_subdomain_add_tag(bfam_subdomain_t *thisSubdomain, const char* tag);

/** Remove a tag from the subdomain
 *
 * \param [in,out] thisSubdomain subdomain to remove the tag from
 * \param [in]     tag           tag of the domain (\0 terminated string)
 *
 * \returns It returns 1 if the tag was removed, 0 otherwise.
 */
int
bfam_subdomain_delete_tag(bfam_subdomain_t *thisSubdomain, const char* tag);

/** Check to see if a subdomain has a tag
 *
 * \param [in,out] thisSubdomain subdomain to search for the tag
 * \param [in]     tag           tag of the domain (\0 terminated string)
 *
 * \return nonzero iff \a thisSubdomain has the tag \a tag
 */
int
bfam_subdomain_has_tag(bfam_subdomain_t *thisSubdomain, const char* tag);

#endif
