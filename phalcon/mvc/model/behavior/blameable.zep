/*
 +------------------------------------------------------------------------+
 | Phalcon Framework                                                      |
 +------------------------------------------------------------------------+
 | Copyright (c) 2011-2015 Phalcon Team (http://www.phalconphp.com)       |
 +------------------------------------------------------------------------+
 | This source file is subject to the New BSD License that is bundled     |
 | with this package in the file docs/LICENSE.txt.                        |
 |                                                                        |
 | If you did not receive a copy of the license and are unable to         |
 | obtain it through the world-wide-web, please send an email             |
 | to license@phalconphp.com so we can send you a copy immediately.       |
 +------------------------------------------------------------------------+
 | Authors: Andres Gutierrez <andres@phalconphp.com>                      |
 |          Eduar Carvajal <eduar@phalconphp.com>                         |
 |          Vladimir Metelitsa <green.cat@me.com>                         |
 +------------------------------------------------------------------------+
 */

namespace Phalcon\Mvc\Model\Behavior;

use Phalcon\Mvc\Model\Behavior;
use Phalcon\Mvc\Model\BehaviorInterface;
use Phalcon\Mvc\ModelInterface;

/**
 * Phalcon\Mvc\Model\Behavior\Blameable
 */
class Blameable extends Behavior implements BehaviorInterface
{
    protected _bahavior;
    
    protected _audit;
    
    protected _auditDetailClassName;
    
    public function __construct(string! bahaviorClass, string! auditClass, string! auditDetailClass)
    {
        let this->_bahavior = new {behaviorClass}();
        let this->_audit = new {auditClass}();
        let this->_auditDetailClassName = auditDetailClass;
    }
    
    /**
     * Listens for notifications from the models manager
     */
    public function notify(string! type, <ModelInterface> model)
    {
        //Fires logAfterCreate if the event is afterCreate
        if (eventType == "afterCreate") {
            return this->auditAfterCreate(model);
        }

        //Fires logAfterUpdate if the event is afterUpdate
        if (eventType == "afterUpdate") {
            return this->auditAfterUpdate(model);
        }
    }

    /**
     * Creates an Audit instance based on the current enviroment
     */
    internal function createAudit(string! type, <ModelInterface> model) -> <Audit>
    {
        var session, request;

        //Get the session service
        let session = model->getDI()->getSession();

        //Get the request service
        let request = model->getDI()->getRequest();

        //Get the username from session
        let this->_audit->user_name = session->get("userName");

        //The model who performed the action
        let this->_audit->model_name = get_class(model);

        //The client IP address
        let this->_audit->ipaddress = request->getClientAddress();

        //Action is an update
        let this->_audit->type = type;

        //Current time
        let this->_audit->created_at = date("Y-m-d H:i:s");
    }

    /**
     * Audits a DELETE operation
     */
    internal function auditAfterCreate(<ModelInterface> model) -> bool
    {
        var metaData, fields, field, auditDetail;
        array details;

        //Create a new audit
        this->createAudit("C", model);
        let metaData = model->getModelsMetaData();
        let fields   = metaData->getAttributes(model);

        foreach (fields as field) {
            let auditDetail = new {this->_auditDetailClassName}();
            let auditDetail->field_name = field;
            let auditDetail->old_value = null;
            let auditDetail->new_value = model->readAttribute(field);

            let details[] = auditDetail;
        }

        let this->_audit->details = details;

        return this->_audit->save();
    }

    /**
     * Audits an UPDATE operation
     */
    internal function auditAfterUpdate(<ModelInterface> model) -> bool
    {
        var changedFields, field, originalData, auditDetail;
        array details;

        let changedFields = model->getChangedFields();

        if (count(changedFields) == 0) {
            return null;
        }

        //Create a new audit
        this->createAudit("U", model);

        //Data the model had before modifications
        let originalData = model->getSnapshotData();

        foreach (changedFields as field) {
            let auditDetail = new {this->_auditDetailClassName}();
            let auditDetail->field_name = field;
            let auditDetail->old_value = originalData[field];
            let auditDetail->new_value = model->readAttribute(field);

            let details[] = auditDetail;
        }

        let this->_audit->details = details;

        return this->_audit->save();
    }
}
